import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class RecentBillsList extends StatelessWidget {
  final AppThemeColors colors;
  final List<Bill> bills;

  const RecentBillsList({super.key, required this.colors, required this.bills});

  static const _weekdays = [
    '',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];
  static const _months = [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Text(
              'Últimos movimientos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: colors.textPrimary,
              ),
            ),
          ),
          ...bills.reversed.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final bill = entry.value;
            final isExpense = bill.cashFlow == 'expense';
            final amountColor = isExpense ? colors.error : colors.success;
            final date = bill.date ?? DateTime.now();

            return Column(
              children: [
                if (i > 0)
                  Divider(
                    height: 1,
                    color: colors.border.withOpacity(0.5),
                    indent: 20,
                    endIndent: 20,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: amountColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            bill.category.icon ?? '📦',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.subcategory.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${bill.category.name} · ${_weekdays[date.weekday]} ${date.day} ${_months[date.month]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}\₡${bill.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
