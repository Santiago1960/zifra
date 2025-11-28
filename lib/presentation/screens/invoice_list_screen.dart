import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/widgets/custom_app_bar.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final List<Invoice> invoices;

  const InvoiceListScreen({super.key, required this.invoices});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final Set<int> _selectedIndexes = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _selectAll = true;
    _selectedIndexes.addAll(List.generate(widget.invoices.length, (i) => i));
  }

  void _onSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIndexes.addAll(List.generate(widget.invoices.length, (i) => i));
      } else {
        _selectedIndexes.clear();
      }
    });
  }

  void _onSelect(int index, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndexes.add(index);
      } else {
        _selectedIndexes.remove(index);
      }
      _selectAll = _selectedIndexes.length == widget.invoices.length;
    });
  }

  Future<void> _openPdf(Invoice invoice) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfGenerator = ref.read(pdfGeneratorServiceProvider);
      final bytes = await pdfGenerator.generatePdf(invoice);

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/factura_${invoice.secuencial}.pdf');
      await file.writeAsBytes(bytes);

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      await OpenFilex.open(file.path);
    } catch (e) {
      // Hide loading indicator if showing
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el PDF: $e')),
        );
      }
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Facturas Seleccionadas (${_selectedIndexes.length})',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 600,
                width: 1000,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: _selectAll,
                                onChanged: _onSelectAll,
                              ),
                            ),
                            const Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                            const Expanded(flex: 2, child: Text('Número', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                            const Expanded(flex: 4, child: Text('Emisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                            const Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                            const Expanded(flex: 3, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                            const SizedBox(width: 50, child: Text('Ver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,))),
                          ],
                        ),
                      ),
                      // Scrollable List
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 15.0,
                          radius: const Radius.circular(5.0),
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: widget.invoices.length,
                            itemBuilder: (context, index) {
                              final invoice = widget.invoices[index];
                              final isSelected = _selectedIndexes.contains(index);
                              final isEven = index % 2 == 0;

                              // Extract only the sequential part
                              final sequentialParts = invoice.secuencial.split('-');
                              final shortSequential = sequentialParts.isNotEmpty ? sequentialParts.last : invoice.secuencial;

                              final baseColor = isEven ? Colors.lightBlue.shade50 : Colors.white;
                              final rowColor = isSelected
                                  ? Color.alphaBlend(Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3), baseColor)
                                  : baseColor;

                              return Container(
                                color: rowColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) => _onSelect(index, value),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: Text(invoice.fechaEmision)),
                                    Expanded(flex: 2, child: Text(shortSequential)),
                                    Expanded(flex: 4, child: Text(invoice.razonSocial)),
                                    Expanded(flex: 2, child: Text('\$${invoice.importeTotal.toStringAsFixed(2)}')),
                                    Expanded(flex: 3, child: Text(invoice.categoria.isEmpty ? 'Sin categoría' : invoice.categoria)),
                                    SizedBox(
                                      width: 50,
                                      child: IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => _openPdf(invoice),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
