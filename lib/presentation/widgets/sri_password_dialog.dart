import 'package:flutter/material.dart';

/// Un período de descarga (año + mes).
class SriPeriod {
  final int year;
  final int month;
  const SriPeriod({required this.year, required this.month});
}

/// Resultado del diálogo: contraseña + lista de períodos seleccionados.
class SriPasswordResult {
  final String password;
  final List<SriPeriod> periods;
  const SriPasswordResult({required this.password, required this.periods});
}

class SriPasswordDialog extends StatefulWidget {
  const SriPasswordDialog({super.key});

  static Future<SriPasswordResult?> show(BuildContext context) {
    return showDialog<SriPasswordResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SriPasswordDialog(),
    );
  }

  @override
  State<SriPasswordDialog> createState() => _SriPasswordDialogState();
}

class _SriPasswordDialogState extends State<SriPasswordDialog> {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Período que el usuario está a punto de agregar
  late int _addYear = DateTime.now().year;
  late int _addMonth = DateTime.now().month;

  // Lista de períodos ya confirmados
  final List<SriPeriod> _periods = [];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _addPeriod() {
    final isDuplicate = _periods.any((p) => p.year == _addYear && p.month == _addMonth);
    if (isDuplicate) return;
    setState(() => _periods.add(SriPeriod(year: _addYear, month: _addMonth)));
  }

  void _removePeriod(int index) => setState(() => _periods.removeAt(index));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_periods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un período para descargar.')),
      );
      return;
    }
    Navigator.of(context).pop(SriPasswordResult(
      password: _passwordController.text.trim(),
      periods: List.unmodifiable(_periods),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF1B78C5)),
          SizedBox(width: 10),
          Flexible(child: Text('Descargar facturas del SRI')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona los períodos a descargar y tu contraseña del SRI.'),
              const SizedBox(height: 20),

              // --- Selector de período a agregar ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _addYear,
                      decoration: const InputDecoration(labelText: 'Año', border: OutlineInputBorder()),
                      items: List.generate(5, (i) => currentYear - i)
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: (v) => setState(() => _addYear = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _addMonth,
                      decoration: const InputDecoration(labelText: 'Mes', border: OutlineInputBorder()),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text(_months[m - 1])))
                          .toList(),
                      onChanged: (v) => setState(() => _addMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Agregar período',
                    icon: const Icon(Icons.add),
                    onPressed: _addPeriod,
                  ),
                ],
              ),

              // --- Lista de períodos agregados ---
              if (_periods.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Períodos seleccionados:', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _periods
                      .asMap()
                      .entries
                      .map((e) => Chip(
                            label: Text('${_months[e.value.month - 1]} ${e.value.year}'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removePeriod(e.key),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // --- Contraseña ---
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña SRI',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'La contraseña es obligatoria' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.download),
          label: Text(_periods.isEmpty
              ? 'Descargar'
              : 'Descargar ${_periods.length} período${_periods.length > 1 ? "s" : ""}'),
        ),
      ],
    );
  }
}
