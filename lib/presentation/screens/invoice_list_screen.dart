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
  final int? projectId;

  const InvoiceListScreen({super.key, required this.invoices, this.projectId});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final Set<String> _selectedIds = {};
  bool _selectAll = false;
  List<Invoice>? _sortedInvoices; // Changed from late to nullable
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<Invoice> get _currentInvoices => _sortedInvoices ?? widget.invoices;

  double get _totalSelectedAmount {
    return widget.invoices
        .where((i) => _selectedIds.contains(i.claveAcceso))
        .fold(0.0, (sum, i) => sum + i.importeTotal);
  }

  @override
  void initState() {
    super.initState();
    _selectAll = true;
    // _sortedInvoices initialization removed to support hot reload safety
    _selectedIds.addAll(widget.invoices.map((i) => i.claveAcceso));
  }

  @override
  void didUpdateWidget(InvoiceListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invoices != oldWidget.invoices) {
      setState(() {
        _sortedInvoices = null; // Reset to new data
        _selectedIds.clear();
        _selectAll = false;
      });
    }
  }

  void _onSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds.addAll(_currentInvoices.map((i) => i.claveAcceso));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _onSelect(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      _selectAll = _selectedIds.length == _currentInvoices.length;
    });
  }

  void _sortData(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      
      // Initialize if null (first sort) or re-sort existing
      _sortedInvoices = List.from(_currentInvoices);
      
      _sortedInvoices!.sort((a, b) {
        int compare = 0;
        switch (columnIndex) {
          case 0: // Fecha
            // Assuming format DD/MM/YYYY
            try {
              final aParts = a.fechaEmision.split('/');
              final bParts = b.fechaEmision.split('/');
              final aDate = DateTime(int.parse(aParts[2]), int.parse(aParts[1]), int.parse(aParts[0]));
              final bDate = DateTime(int.parse(bParts[2]), int.parse(bParts[1]), int.parse(bParts[0]));
              compare = aDate.compareTo(bDate);
            } catch (e) {
              compare = a.fechaEmision.compareTo(b.fechaEmision);
            }
            break;
          case 1: // Número (Secuencial)
             compare = a.secuencial.compareTo(b.secuencial);
             break;
          case 2: // Emisor
            compare = a.razonSocial.compareTo(b.razonSocial);
            break;
          case 3: // Total
            compare = a.importeTotal.compareTo(b.importeTotal);
            break;
          case 4: // Categoría
            final catA = a.categoria.isEmpty ? 'Sin categoría' : a.categoria;
            final catB = b.categoria.isEmpty ? 'Sin categoría' : b.categoria;
            compare = catA.compareTo(catB);
            break;
        }
        return ascending ? compare : -compare;
      });
      
       // Selection is preserved because we use IDs now
    });
  }

  String _formatDate(String date) {
    try {
      if (date.contains('T')) {
        final parsed = DateTime.parse(date);
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }
  
  Widget _buildHeaderCell(String label, int index, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          _sortData(index, _sortColumnIndex == index ? !_sortAscending : true);
        },
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
            if (_sortColumnIndex == index)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
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
                'Facturas Seleccionadas (${_selectedIds.length})',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Toca en los títulos para ordenar',
                style: Theme.of(context).textTheme.bodySmall!,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 500,
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
                            _buildHeaderCell('Fecha', 0, flex: 2),
                            _buildHeaderCell('Número', 1, flex: 2),
                            _buildHeaderCell('Emisor', 2, flex: 4),
                            _buildHeaderCell('Total', 3, flex: 2),
                            _buildHeaderCell('Categoría', 4, flex: 3),
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
                            itemCount: _currentInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _currentInvoices[index];
                              final isSelected = _selectedIds.contains(invoice.claveAcceso);
                              final isEven = index % 2 == 0;

                              // Extract only the sequential part
                              final sequentialParts = invoice.secuencial.split('-');
                              final shortSequential = sequentialParts.isNotEmpty ? sequentialParts.last : invoice.secuencial;

                              final baseColor = isEven ? Colors.lightBlue.shade50 : Colors.white;
                              final rowColor = isSelected
                                  ? Color.alphaBlend(Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3), baseColor)
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
                                        onChanged: (value) => _onSelect(invoice.claveAcceso, value),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: Text(_formatDate(invoice.fechaEmision))),
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
              const SizedBox(height: 20),
              Container(
                width: 1000,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Seleccionado:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${_totalSelectedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
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
