

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/domain/utils/invoice_validator.dart';
import 'package:zifra/presentation/screens/invoice_list_screen.dart';

class InvoiceDropZone extends StatefulWidget {
  const InvoiceDropZone({super.key});

  @override
  State<InvoiceDropZone> createState() => _InvoiceDropZoneState();
}

class _InvoiceDropZoneState extends State<InvoiceDropZone> {
  bool _dragging = false;
  final List<FileValidationResult> _files = [];

  Future<void> _processFiles(List<XFile> files) async {
    for (final file in files) {
      if (!file.name.toLowerCase().endsWith('.xml')) {
        setState(() {
          _files.add(FileValidationResult(
            file: file,
            isValid: false,
            errorMessage: 'No es un archivo XML',
          ));
        });
        continue;
      }

      try {
        final content = await file.readAsString();
        final error = InvoiceValidator.validate(content);
        
        if (error == null) {
          // Check for duplicates
          final invoice = InvoiceValidator.parse(content);
          if (invoice != null) {
            // Check against existing files
            final isDuplicate = _files.any((f) => f.invoice?.claveAcceso == invoice.claveAcceso);
            if (isDuplicate) {
               setState(() {
                _files.add(FileValidationResult(
                  file: file,
                  isValid: false,
                  errorMessage: 'Factura duplicada',
                  invoice: invoice,
                ));
              });
              continue;
            }
             setState(() {
              _files.add(FileValidationResult(
                file: file,
                isValid: true,
                errorMessage: null,
                invoice: invoice,
              ));
            });
          } else {
             setState(() {
              _files.add(FileValidationResult(
                file: file,
                isValid: false,
                errorMessage: 'Error al procesar la factura',
              ));
            });
          }
        } else {
          setState(() {
            _files.add(FileValidationResult(
              file: file,
              isValid: false,
              errorMessage: error,
            ));
          });
        }
      } catch (e) {
        setState(() {
          _files.add(FileValidationResult(
            file: file,
            isValid: false,
            errorMessage: 'Error al leer el archivo',
          ));
        });
      }
    }
    
    setState(() {
      _files.sort((a, b) {
        if (a.isValid == b.isValid) return 0;
        return a.isValid ? 1 : -1;
      });
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.files.map((f) => XFile(f.path!)).toList();
      _processFiles(files);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropTarget(
          onDragDone: (detail) {
            setState(() {
              _dragging = false;
            });
            _processFiles(detail.files);
          },
          onDragEntered: (detail) {
            setState(() {
              _dragging = true;
            });
          },
          onDragExited: (detail) {
            setState(() {
              _dragging = false;
            });
          },
          child: GestureDetector(
            onTap: _pickFiles,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _dragging
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[100],
                border: Border.all(
                  color: _dragging
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[400]!,
                  width: 2,
                  style: BorderStyle.solid, // Dotted border requires custom painter or package, solid for now
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: _dragging
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arrastra tus facturas XML aquí',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _dragging
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'o haz click para seleccionar',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (_files.any((f) => f.isValid))
            SizedBox(
              child: ElevatedButton.icon(
                onPressed: () {
                  final validInvoices = _files
                      .where((f) => f.isValid && f.invoice != null)
                      .map((f) => f.invoice!)
                      .toList();
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InvoiceListScreen(invoices: validInvoices),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Procesar Facturas'),
              ),
            ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Archivos procesados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final item = _files[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    item.isValid ? Icons.check_circle : Icons.error,
                    color: item.isValid ? Colors.green : Colors.red,
                  ),
                  title: Text(item.file.name),
                  subtitle: item.isValid
                      ? const Text('Válido', style: TextStyle(color: Colors.green))
                      : Text(item.errorMessage ?? 'Inválido',
                          style: const TextStyle(color: Colors.red)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _files.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}



class FileValidationResult {
  final XFile file;
  final bool isValid;
  final String? errorMessage;
  final Invoice? invoice;

  FileValidationResult({
    required this.file,
    required this.isValid,
    this.errorMessage,
    this.invoice,
  });
}
