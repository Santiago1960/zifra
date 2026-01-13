import 'package:flutter/material.dart';

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({super.key});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  // Map of field key to display name
  final Map<String, String> _availableFields = {
    'ruc': 'RUC',
    'claveAcceso': 'Clave de Acceso',
    'dirMatriz': 'Dirección Matriz',
    'dirEstablecimiento': 'Dirección Establecimiento',
    'contribuyenteEspecial': 'Contribuyente Especial',
    'obligadoContabilidad': 'Obligado Contabilidad',
    'tipoIdentificacionComprador': 'Tipo Identificación Comprador',
    'razonSocialComprador': 'Razón Social Comprador',
    'identificacionComprador': 'Identificación Comprador',
    'totalSinImpuestos': 'Total Sin Impuestos',
    'totalDescuento': 'Total Descuento',
    'valorIVA': 'Valor IVA',
    'propina': 'Propina',
    'numeroAutorizacion': 'Número Autorización',
    'fechaAutorizacion': 'Fecha Autorización',
  };

  final Set<String> _selectedFields = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Opciones de Exportación'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campos incluidos por defecto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Fecha Emisión\n• Número Completo\n• Emisor\n• Total\n• Categoría',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona campos adicionales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _availableFields.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(entry.value),
                      value: _selectedFields.contains(entry.key),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFields.add(entry.key);
                          } else {
                            _selectedFields.remove(entry.key);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, _selectedFields.toList());
          },
          icon: const Icon(Icons.download),
          label: const Text('Exportar'),
        ),
      ],
    );
  }
}
