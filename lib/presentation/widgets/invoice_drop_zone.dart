import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:zifra/data/datasources/remote/project_remote_datasource.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/domain/utils/invoice_validator.dart';
import 'package:zifra/presentation/providers/auth_provider.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/screens/invoice_list_screen.dart';
import 'package:zifra/presentation/widgets/project_creation_dialog.dart';
import 'package:zifra/core/exceptions/duplicate_invoices_exception.dart';

class InvoiceDropZone extends ConsumerStatefulWidget {
  const InvoiceDropZone({super.key});

  @override
  ConsumerState<InvoiceDropZone> createState() => _InvoiceDropZoneState();
}

class _InvoiceDropZoneState extends ConsumerState<InvoiceDropZone> {
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
                onPressed: () async {
                  final validInvoices = _files
                      .where((f) => f.isValid && f.invoice != null)
                      .map((f) => f.invoice!)
                      .toList();
                  
                  // Show dialog
                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (context) => const ProjectCreationDialog(),
                  );

                  if (result != null) {
                    final clientName = result['client']!;
                    final projectName = result['project']!;
                    
                    // Get RUC from auth
                    final user = ref.read(authProvider).user;
                    if (user == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error: Usuario no autenticado'),backgroundColor: Colors.red, duration: Duration(seconds: 10), showCloseIcon: true,),
                          );
                        }
                        return;
                    }

                    try {
                        // Show loading?
                        // For now just await
                        final projectId = await ref.read(projectRemoteDataSourceProvider).createProject(
                            clientName,
                            projectName,
                            user.ruc,
                        );

                        try {
                          // Save invoices
                          await ref.read(invoiceRemoteDataSourceProvider).saveInvoices(validInvoices, projectId);
                        } on DuplicateInvoicesException catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Facturas Duplicadas'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Las siguientes facturas ya están registradas en otros proyectos:'),
                                      const SizedBox(height: 10),
                                      ...e.messages.map((msg) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('• $msg', style: const TextStyle(fontSize: 13)),
                                      )),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return;
                        } catch (e) {
                          if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al guardar facturas: $e'), backgroundColor: Colors.red, duration:  const Duration(seconds: 10), showCloseIcon: true,),
                              );
                          }
                          return; // Stop navigation if saving invoices fails
                        }

                        if (context.mounted) {
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                builder: (context) => InvoiceListScreen(
                                invoices: validInvoices,
                                projectId: projectId,
                                ),
                                ),
                            );
                        }
                    } on ProjectExistsException catch (e) {
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message), backgroundColor: Colors.red, duration: const Duration(seconds: 10), showCloseIcon: true,),
                            );
                        }
                    } catch (e) {
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al crear proyecto: $e'), backgroundColor: Colors.red, duration:  const Duration(seconds: 10), showCloseIcon: true,),
                            );
                        }
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: Text('Procesar ${_files.where((f) => f.isValid && f.invoice != null).length} Facturas'),
              ),
            ),
          const SizedBox(height: 10),
Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Archivos procesados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _files.clear();
                  });
                },
                icon: const Icon(Icons.delete_sweep, size: 20),
                label: const Text('Limpiar todo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
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
