import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class PayButton extends StatelessWidget {
  final AppThemeColors colors;
  final Note note;
  final VoidCallback onPay;

  const PayButton({
    super.key,
    required this.colors,
    required this.note,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final bill = note.bill!;
    final isExpense = bill.cashFlow == 'expense';
    final accent = isExpense ? colors.error : colors.success;

    return GestureDetector(
      onTap: onPay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(color: accent.withOpacity(0.25), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense ? Icons.payments_outlined : Icons.savings_outlined,
              size: 15,
              color: accent,
            ),
            const SizedBox(width: 8),
            Text(
              isExpense
                  ? 'Registrar pago · \u20a1${bill.amount.toStringAsFixed(0)}'
                  : 'Registrar ingreso · \u20a1${bill.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
