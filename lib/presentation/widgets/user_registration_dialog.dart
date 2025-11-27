import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';

class UserRegistrationDialog extends ConsumerStatefulWidget {
  const UserRegistrationDialog({super.key});

  @override
  ConsumerState<UserRegistrationDialog> createState() => _UserRegistrationDialogState();
}

class _UserRegistrationDialogState extends ConsumerState<UserRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rucController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _rucController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).registerUser(
            _nameController.text.trim(),
            _rucController.text.trim(),
          );
      // Dialog will be closed by the parent widget based on state change, 
      // or we can close it here if it was pushed. 
      // Since this is likely an overlay or conditional render, we might not need to pop.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/icon.png',
            height: 30,
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('Bienvenido a Zifra'),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor ingresa tus datos para continuar.'),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rucController,
              decoration: const InputDecoration(
                labelText: 'Cédula o RUC',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa cédula o RUC';
                }
                if (value.length != 10 && value.length != 13) {
                  return 'La identificación debe tener 10 o 13 dígitos';
                }
                return null;
              },
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
