import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/ledger.dart';

class DailyExpenseChart extends StatelessWidget {
  const DailyExpenseChart({super.key, required this.dailyTotals});

  final Map<DateTime, DailyTotals> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final entries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxCredit = entries.fold<double>(0, (m, e) => math.max(m, e.value.credit));
    final maxDebit = entries.fold<double>(0, (m, e) => math.max(m, e.value.debit));
    final bound = math.max(maxCredit, maxDebit);
    final chartMax = bound <= 0 ? 100.0 : bound * 1.2;
    final creditColor = Colors.green.shade600;
    final debitColor = Colors.red.shade600;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: creditColor, label: 'Credit'),
            const SizedBox(width: 16),
            _LegendDot(color: debitColor, label: 'Expense'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              minY: -chartMax,
              maxY: chartMax,
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Theme.of(context).colorScheme.outline,
                    strokeWidth: 1,
                  ),
                ],
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = entries[group.x.toInt()].key;
                    final totals = entries[group.x.toInt()].value;
                    return BarTooltipItem(
                      '${DateFormat.MMMd().format(day)}\n'
                      'Credit  ₹${totals.credit.toStringAsFixed(0)}\n'
                      'Expense  ₹${totals.debit.toStringAsFixed(0)}\n'
                      'Net  ₹${totals.net.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: chartMax / 2,
                    getTitlesWidget: (value, _) => Text(
                      NumberFormat.compact().format(value),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final day = entries[index].key.day;
                      if (day != 1 && day % 5 != 0 && day != entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('$day', style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < entries.length; i++)
                  BarChartGroupData(
                    x: i,
                    groupVertically: false,
                    barsSpace: 1,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: entries[i].value.credit,
                        color: creditColor,
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        fromY: 0,
                        toY: -entries[i].value.debit,
                        color: debitColor,
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
