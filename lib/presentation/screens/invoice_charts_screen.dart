import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/domain/entities/category.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/presentation/providers/category_provider.dart';

class InvoiceChartsScreen extends ConsumerWidget {
  final List<Invoice> invoices;

  const InvoiceChartsScreen({super.key, required this.invoices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final categoryData = _calculateCategoryData(invoices, categories);
    final totalAmount = invoices.fold(0.0, (sum, i) => sum + i.importeTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Gastos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total',
                    value: '\$${totalAmount.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Facturas',
                    value: invoices.length.toString(),
                    icon: Icons.receipt,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gastos por Categoría',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: categoryData.isEmpty
                              ? 0
                              : categoryData.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.blueGrey,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final categoryName = categoryData[group.x.toInt()].categoryName;
                                return BarTooltipItem(
                                  '$categoryName\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '\$${rod.toY.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.yellow,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  if (value.toInt() >= categoryData.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      categoryData[value.toInt()].categoryName.length > 10
                                          ? '${categoryData[value.toInt()].categoryName.substring(0, 8)}...'
                                          : categoryData[value.toInt()].categoryName,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '\$${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          barGroups: categoryData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: data.amount,
                                  color: data.color,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pie Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribución Porcentual',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: categoryData.map((data) {
                                  final isLarge = data.percentage > 10;
                                  return PieChartSectionData(
                                    color: data.color,
                                    value: data.amount,
                                    title: '${data.percentage.toStringAsFixed(1)}%',
                                    radius: isLarge ? 60 : 50,
                                    titleStyle: TextStyle(
                                      fontSize: isLarge ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryData.map((data) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: data.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          data.categoryName,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CategoryChartData> _calculateCategoryData(
      List<Invoice> invoices, List<Category> categories) {
    final Map<int?, double> totals = {};
    double totalAmount = 0;

    for (var invoice in invoices) {
      totals[invoice.categoryId] = (totals[invoice.categoryId] ?? 0) + invoice.importeTotal;
      totalAmount += invoice.importeTotal;
    }

    final List<_CategoryChartData> data = [];

    totals.forEach((categoryId, amount) {
      String name = 'Sin categoría';
      Color color = Colors.grey;

      if (categoryId != null) {
        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => const Category(name: 'Desconocida', userId: 0, color: '808080'),
        );
        name = category.name;
        try {
          color = Color(int.parse('0xFF${category.color}'));
        } catch (_) {
          color = Colors.grey;
        }
      }

      data.add(_CategoryChartData(
        categoryName: name,
        amount: amount,
        percentage: totalAmount > 0 ? (amount / totalAmount * 100) : 0,
        color: color,
      ));
    });

    // Sort by amount descending
    data.sort((a, b) => b.amount.compareTo(a.amount));
    return data;
  }
}

class _CategoryChartData {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  _CategoryChartData({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
