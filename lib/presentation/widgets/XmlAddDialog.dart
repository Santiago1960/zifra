// ignore: file_names
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/domain/utils/invoice_validator.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/widgets/invoice_drop_zone.dart'; // Para FileValidationResult

class XmlAddDialog extends ConsumerStatefulWidget {
  final List<Invoice> currentInvoices; // Las facturas que ya están en la tabla
  final int projectId;

  const XmlAddDialog({
    super.key, 
    required this.currentInvoices,
    required this.projectId,
  });

  @override
  ConsumerState<XmlAddDialog> createState() => _XmlAddDialogState();
}

class _XmlAddDialogState extends ConsumerState<XmlAddDialog> {
  final List<FileValidationResult> _newFiles = [];
  bool _isProcessing = false;
  bool _dragging = false;

  Future<void> _processFiles(List<XFile> files) async {
    for (final file in files) {
      if (!file.name.toLowerCase().endsWith('.xml')) {
        _addResult(file, false, 'No es un archivo XML');
        continue;
      }

      try {
        final content = await file.readAsString();
        final error = InvoiceValidator.validate(content);
        
        if (error == null) {
          final invoice = InvoiceValidator.parse(content);
          if (invoice != null) {
            // Validación estricta usando la clave única del SRI
            final isDuplicate = widget.currentInvoices.any((f) => f.claveAcceso == invoice.claveAcceso) ||
                               _newFiles.any((f) => f.invoice?.claveAcceso == invoice.claveAcceso);

            if (isDuplicate) {
              _addResult(file, false, 'Factura ya existe en el listado', invoice: invoice);
            } else {
              _addResult(file, true, null, invoice: invoice);
            }
          }
        } else {
          _addResult(file, false, error);
        }
      } catch (e) {
        _addResult(file, false, 'Error al leer archivo');
      }
    }
  }

  void _addResult(XFile file, bool isValid, String? error, {Invoice? invoice}) {
    setState(() {
      _newFiles.add(FileValidationResult(
        file: file,
        isValid: isValid,
        errorMessage: error,
        invoice: invoice,
      ));
    });
  }

  Future<void> _saveNewInvoices() async {
    setState(() => _isProcessing = true);
    try {
      final toSave = _newFiles
          .where((f) => f.isValid && f.invoice != null)
          .map((f) => f.invoice!)
          .toList();

      // Guardado directo en el backend (Puerto 8083 en Digital Ocean)
      await ref.read(invoiceRemoteDataSourceProvider).saveInvoices(toSave, widget.projectId);
      
      if (mounted) {
        Navigator.pop(context, toSave); // Retornamos las nuevas facturas procesadas
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildFilesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _newFiles.length,
      itemBuilder: (context, index) {
        final item = _newFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item.isValid ? Icons.check_circle : Icons.error,
              color: item.isValid ? Colors.green : Colors.red,
            ),
            title: Text(item.file.name, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              item.isValid ? 'Listo para añadir' : (item.errorMessage ?? 'Error'),
              style: TextStyle(color: item.isValid ? Colors.green : Colors.red, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _newFiles.removeAt(index)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _newFiles.where((f) => f.isValid).length;

    return AlertDialog(
      title: const Text('Añadir nuevas facturas'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropTarget(
                onDragDone: (detail) {
                  setState(() => _dragging = false);
                  _processFiles(detail.files);
                },
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _dragging ? Colors.blue.withValues(alpha: 0.05) : Colors.grey[50],
                    border: Border.all(
                      color: _dragging ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_copy_outlined, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Suelta tus nuevos XMLs aquí', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_newFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFilesList(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (validCount > 0 && !_isProcessing) ? _saveNewInvoices : null,
          child: _isProcessing 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text('Añadir $validCount facturas'),
        ),
      ],
    );
  }
}