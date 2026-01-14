import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/domain/entities/category.dart';
import 'package:zifra/presentation/providers/category_provider.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';

class CategoryManagerDialog extends ConsumerStatefulWidget {
  const CategoryManagerDialog({super.key});

  @override
  ConsumerState<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<CategoryManagerDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = 'FF5733'; // Default color
  Category? _editingCategory;

  final List<String> _presetColors = [
    'FF5733', // Orange
    '33FF57', // Green
    '3357FF', // Blue
    'FF33A8', // Pink
    '33FFF5', // Cyan
    'FFFF33', // Yellow
    'A833FF', // Purple
    'FF8C33', // Dark Orange
    '808080', // Grey
    '000000', // Black
  ];

  Future<void> _saveCategory() async {
    if (_nameController.text.isEmpty) return;

    Map<String, String>? result;

    if (_editingCategory != null) {
      result = await ref.read(categoryProvider.notifier).updateCategory(
            _editingCategory!.copyWith(
              name: _nameController.text,
              color: _selectedColor,
            ),
          );
    } else {
      final user = ref.read(authProvider).user;
      if (user == null) {
        // Should not happen if we are here, but safety check
        return;
      }
      
      result = await ref.read(categoryProvider.notifier).addCategory(
            Category(
              name: _nameController.text,
              userId: user.ruc,
              color: _selectedColor,
            ),
          );
    }

    if (result != null) {
      final type = result['type'];
      
      if (type == 'exact') {
        // Error: duplicado exacto
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Ya existe una categoría con el nombre "${result!['existingName']}"'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      } else if (type == 'similar') {
        // Advertencia: nombre similar
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Categoría similar'),
              content: Text(
                'Ya existe una categoría llamada "${result!['existingName']}".\n\n'
                '¿Deseas crear "${_nameController.text}" de todas formas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Crear de todas formas'),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            // Usuario confirmó, forzar creación (llamar directamente al datasource)
            try {
              final notifier = ref.read(categoryProvider.notifier);
              if (_editingCategory != null) {
                await notifier.dataSource.updateCategory(
                  _editingCategory!.copyWith(
                    name: _nameController.text,
                    color: _selectedColor,
                  ),
                );
              } else {
                // Crear directamente sin validación
                final user = ref.read(authProvider).user;
                if (user != null) {
                  await notifier.dataSource.addCategory(
                    Category(
                      name: _nameController.text,
                      userId: user.ruc,
                      color: _selectedColor,
                    ),
                  );
                }
              }
              await notifier.fetchCategories();
              _resetForm();
            } catch (e) {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: const Text('Error al crear la categoría'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                );
              }
            }
          }
        }
      } else if (type == 'error') {
        // Error genérico
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(result!['message'] ?? 'Error desconocido'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }
    } else {
      // Éxito, limpiar el formulario
      _resetForm();
    }
  }

  void _editCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
      _selectedColor = category.color;
    });
  }

  Future<void> _deleteCategory(int id, String categoryName) async {
    final deleted = await ref.read(categoryProvider.notifier).deleteCategory(
      id,
      confirmDelete: () async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar la categoría "$categoryName"?\n\n'
              'Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ?? false; // Si el usuario cierra el diálogo, se considera como cancelar
      },
    );

    if (deleted && _editingCategory?.id == id) {
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _editingCategory = null;
      _nameController.clear();
      _selectedColor = 'FF5733';
    });
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('0xFF$hex'));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).where((c) => c.active).toList();

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Administrar Categorías',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Color Picker (Simple dropdown or row of dots)
                PopupMenuButton<String>(
                  initialValue: _selectedColor,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hexToColor(_selectedColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  onSelected: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  itemBuilder: (context) {
                    return _presetColors.map((color) {
                      return PopupMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _hexToColor(color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('#$color'),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveCategory,
                  child: Text(_editingCategory == null ? 'Agregar' : 'Actualizar'),
                ),
                if (_editingCategory != null)
                  TextButton(
                    onPressed: _resetForm,
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _hexToColor(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editCategory(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(category.id!, category.name),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
