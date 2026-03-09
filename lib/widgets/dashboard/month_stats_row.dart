import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/widgets/dashboard/savings_progress_card.dart';

class MonthStatsRow extends StatelessWidget {
  final AppThemeColors colors;
  final double income;
  final double expense;
  final double savings;
  final double totalIncome;
  final double savingsDeposits;
  final double savingsWithdrawals;

  const MonthStatsRow({
    super.key,
    required this.colors,
    required this.income,
    required this.expense,
    required this.savings,
    required this.totalIncome,
    required this.savingsDeposits,
    required this.savingsWithdrawals,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavingBloc, SavingState>(
      builder: (context, state) {
        Saving? activeSaving;

        if (state is SavingLoaded && state.savings.isNotEmpty) {
          final actives = state.savings.where((s) => !s.isCompleted).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          activeSaving = actives.isNotEmpty ? actives.first : null;
        }
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                colors: colors,
                label: 'Ingresos',
                amount: income,
                icon: Icons.arrow_downward_rounded,
                iconColor: colors.success,
                bgColor: colors.success.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                colors: colors,
                label: 'Egresos',
                amount: expense,
                icon: Icons.arrow_upward_rounded,
                iconColor: colors.error,
                bgColor: colors.error.withOpacity(0.1),
              ),
            ),
            if (activeSaving != null && activeSaving.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SavingsProgressCard(
                  colors: colors,
                  currentAmount: activeSaving.currentAmount,
                  goalAmount: activeSaving.goalAmount,
                  name: activeSaving.name,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final AppThemeColors colors;
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.colors,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\u20a1${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
