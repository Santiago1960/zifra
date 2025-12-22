import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zifra/domain/entities/category.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/presentation/providers/category_provider.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';
import 'package:zifra/presentation/widgets/category_manager_dialog.dart';
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
  
  // Filtros
  DateTimeRange? _dateFilter;
  String _issuerFilter = '';
  Set<int?> _categoryFilter = {}; // null representa "Sin categoría"
  final TextEditingController _issuerFilterController = TextEditingController();
  
  // Lista local mutable para mantener cambios de categoría
  List<Invoice>? _localInvoices;

  List<Invoice> get _filteredInvoices {
    // Usar lista local si existe, sino widget.invoices
    final sourceInvoices = _localInvoices ?? widget.invoices;
    var result = sourceInvoices;
    
    // Filtro de fecha
    if (_dateFilter != null) {
      result = result.where((invoice) {
        try {
          DateTime invoiceDate;
          
          // Detectar formato de fecha
          if (invoice.fechaEmision.contains('T')) {
            // Formato ISO 8601: 2025-10-27T00:00:00.000
            invoiceDate = DateTime.parse(invoice.fechaEmision);
          } else if (invoice.fechaEmision.contains('/')) {
            // Formato DD/MM/YYYY
            final parts = invoice.fechaEmision.split('/');
            invoiceDate = DateTime(
              int.parse(parts[2]), 
              int.parse(parts[1]), 
              int.parse(parts[0])
            );
          } else {
            return true; // Incluir si no se puede determinar el formato
          }
          
          // Normalizar fechas a medianoche para comparación correcta
          final normalizedInvoiceDate = DateTime(invoiceDate.year, invoiceDate.month, invoiceDate.day);
          final normalizedStart = DateTime(_dateFilter!.start.year, _dateFilter!.start.month, _dateFilter!.start.day);
          final normalizedEnd = DateTime(_dateFilter!.end.year, _dateFilter!.end.month, _dateFilter!.end.day);
          
          // Comparación inclusiva usando compareTo
          return normalizedInvoiceDate.compareTo(normalizedStart) >= 0 && 
                 normalizedInvoiceDate.compareTo(normalizedEnd) <= 0;
        } catch (e) {
          return true; // Si hay error de parsing, incluir la factura
        }
      }).toList();
    }
    
    // Filtro de emisor
    if (_issuerFilter.isNotEmpty) {
      result = result.where((i) => 
        i.razonSocial.toLowerCase().contains(_issuerFilter.toLowerCase())
      ).toList();
    }
    
    // Filtro de categoría
    if (_categoryFilter.isNotEmpty) {
      result = result.where((i) => 
        _categoryFilter.contains(i.categoryId)
      ).toList();
    }
    
    return result;
  }

  List<Invoice> get _currentInvoices => _sortedInvoices ?? _filteredInvoices;

  double get _totalSelectedAmount {
    return _filteredInvoices
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
        // Limpiar filtros
        _dateFilter = null;
        _issuerFilter = '';
        _categoryFilter.clear();
        // Resetear lista local
        _localInvoices = null;
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
      _sortedInvoices = List.from(_filteredInvoices);
      
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
            final categories = ref.read(categoryProvider);
            final catA = categories.firstWhere((c) => c.id != null && c.id == a.categoryId, orElse: () => const Category(name: 'Sin categoría', userId: 0, color: '000000')).name;
            final catB = categories.firstWhere((c) => c.id != null && c.id == b.categoryId, orElse: () => const Category(name: 'Sin categoría', userId: 0, color: '000000')).name;
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

  Future<void> _updateInvoiceCategory(Invoice invoice, int? categoryId) async {
    // Actualizar UI inmediatamente para respuesta rápida
    setState(() {
      _localInvoices ??= List.from(widget.invoices);
      final index = _localInvoices!.indexWhere((i) => i.claveAcceso == invoice.claveAcceso);
      if (index != -1) {
        _localInvoices![index] = invoice.copyWith(categoryId: categoryId);
      }
      _sortedInvoices = null;
    });

    // Persistir en el backend
    try {
      final datasource = ref.read(invoiceRemoteDataSourceProvider);
      final success = await datasource.updateInvoiceCategory(invoice.claveAcceso, categoryId);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la categoría')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _dateFilter = null;
      _issuerFilter = '';
      _issuerFilterController.clear(); // Limpiar el TextField
      _categoryFilter.clear();
      _sortedInvoices = null; // Reset ordenamiento
    });
  }

  bool get _hasActiveFilters => 
    _dateFilter != null || 
    _issuerFilter.isNotEmpty || 
    _categoryFilter.isNotEmpty;

  Future<void> _assignCategoryToFiltered() async {
    if (_filteredInvoices.isEmpty) return;
    
    final categories = ref.read(categoryProvider);
    
    final selectedCategory = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se asignará a ${_filteredInvoices.length} facturas filtradas'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${cat.color}')),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                )),
              ],
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    
    if (selectedCategory != null) {
      for (final invoice in _filteredInvoices) {
        await _updateInvoiceCategory(invoice, selectedCategory);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría asignada a ${_filteredInvoices.length} facturas')),
        );
      }
    }
  }


  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _issuerFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).where((c) => c.active).toList();

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
              SizedBox(
                width: 1000,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facturas Seleccionadas (${_selectedIds.length})',
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Toca en los títulos para ordenar',
                          style: Theme.of(context).textTheme.bodySmall!,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const CategoryManagerDialog(),
                        );
                      },
                      icon: const Icon(Icons.category),
                      label: const Text('Administrar Categorías'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Barra de filtros
              SizedBox(
                width: 1000,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Filtros:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            // Filtro de fecha
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    initialDateRange: _dateFilter,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _dateFilter = picked;
                                      _sortedInvoices = null;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _dateFilter == null
                                        ? ''
                                        : '${_formatDate('${_dateFilter!.start.day}/${_dateFilter!.start.month}/${_dateFilter!.start.year}')} - ${_formatDate('${_dateFilter!.end.day}/${_dateFilter!.end.month}/${_dateFilter!.end.year}')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Filtro de emisor
                            Expanded(
                              child: TextField(
                                controller: _issuerFilterController,
                                decoration: const InputDecoration(
                                  labelText: 'Emisor',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _issuerFilter = value;
                                    _sortedInvoices = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Filtro de categoría
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final selected = await showDialog<Set<int?>>(
                                    context: context,
                                    builder: (context) => _CategoryFilterDialog(
                                      categories: categories,
                                      selectedCategories: _categoryFilter,
                                    ),
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      _categoryFilter = selected;
                                      _sortedInvoices = null;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Categorías',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _categoryFilter.isEmpty
                                        ? ''
                                        : '${_categoryFilter.length} seleccionadas',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_hasActiveFilters)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Limpiar filtros',
                                onPressed: _clearFilters,
                              ),
                            if (_hasActiveFilters && _filteredInvoices.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _assignCategoryToFiltered,
                                icon: const Icon(Icons.category, size: 18),
                                label: Text('Asignar a ${_filteredInvoices.length}'),
                              ),
                          ],
                        ),
                        // Chips de filtros activos
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (_dateFilter != null)
                                Chip(
                                  label: Text('Fecha: ${_formatDate('${_dateFilter!.start.day}/${_dateFilter!.start.month}/${_dateFilter!.start.year}')} - ${_formatDate('${_dateFilter!.end.day}/${_dateFilter!.end.month}/${_dateFilter!.end.year}')}'),
                                  onDeleted: () => setState(() {
                                    _dateFilter = null;
                                    _sortedInvoices = null;
                                  }),
                                ),
                              if (_issuerFilter.isNotEmpty)
                                Chip(
                                  label: Text('Emisor: $_issuerFilter'),
                                  onDeleted: () => setState(() {
                                    _issuerFilter = '';
                                    _issuerFilterController.clear();
                                    _sortedInvoices = null;
                                  }),
                                ),
                              if (_categoryFilter.isNotEmpty)
                                Chip(
                                  label: Text('Categorías: ${_categoryFilter.length}'),
                                  onDeleted: () => setState(() {
                                    _categoryFilter.clear();
                                    _sortedInvoices = null;
                                  }),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          // Only set value if it exists in the categories list
                                          value: invoice.categoryId != null && 
                                                 categories.any((c) => c.id == invoice.categoryId)
                                              ? invoice.categoryId
                                              : null,
                                          hint: const Text('Sin categoría'),
                                          isExpanded: true,
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text('Sin categoría'),
                                            ),
                                            ...categories.map((category) {
                                              return DropdownMenuItem<int>(
                                                value: category.id,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Color(int.parse('0xFF${category.color}')),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(category.name),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            _updateInvoiceCategory(invoice, value);
                                          },
                                        ),
                                      ),
                                    ),
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

class _CategoryFilterDialog extends StatefulWidget {
  final List<Category> categories;
  final Set<int?> selectedCategories;

  const _CategoryFilterDialog({
    required this.categories,
    required this.selectedCategories,
  });

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  late Set<int?> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar por Categorías'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Sin categoría'),
                value: _selected.contains(null),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selected.add(null);
                    } else {
                      _selected.remove(null);
                    }
                  });
                },
              ),
              ...widget.categories.map((category) {
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${category.color}')),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                  value: _selected.contains(category.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(category.id);
                      } else {
                        _selected.remove(category.id);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            setState(() => _selected.clear());
          },
          child: const Text('Limpiar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
