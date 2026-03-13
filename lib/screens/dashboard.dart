import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_state.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/providers/user/user_provider.dart';
import 'package:where_ma_money_go/widgets/dashboard/balance_card.dart';
import 'package:where_ma_money_go/widgets/dashboard/category_pie_chart.dart';
import 'package:where_ma_money_go/widgets/dashboard/month_stats_row.dart';
import 'package:where_ma_money_go/widgets/dashboard/recent_bills.dart';
import 'package:where_ma_money_go/widgets/dashboard/savings_progress_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _month;

  bool _isEnvelopeMovement(Bill b) =>
      b.category.name.toLowerCase().contains('sobre');
  bool _isSavingMovement(Bill b) =>
      b.category.name.toLowerCase().contains('ahorro');

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    context.read<BillsBloc>().add(LoadBills());
    context.read<SavingBloc>().add(LoadSavings());
  }

  List<Bill> _thisMonth(List<Bill> bills) {
    return bills.where((b) {
      final d = b.date ?? DateTime.now();
      return d.year == _month.year && d.month == _month.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<BillsBloc, BillsState>(
          builder: (context, state) {
            if (state is BillsLoading) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.primary,
                ),
              );
            }

            if (state is BillsError) {
              return _ErrorView(
                colors: colors,
                onRetry: () => context.read<BillsBloc>().add(LoadBills()),
              );
            }

            final allBills = state is BillsLoaded ? state.bills : <Bill>[];
            final monthBills = _thisMonth(allBills);

            // ── Balance general ───────────────────────────────────────────────
            // Movimientos normales y sobres: income suma, expense resta
            // Ahorros están INVERTIDOS: income = sacás del balance (resta),
            //                           expense = regresa al balance (suma)
            double balance = 0.0;
            double balanceIncome = 0.0;
            double balanceExpense = 0.0;
            for (final b in monthBills) {
              final isSaving = _isSavingMovement(b);
              final isEnvelope = _isEnvelopeMovement(b);
              final isIncome = b.cashFlow == 'income';
              // Ahorros invertidos: income resta del balance, expense suma
              final countsAsIncome = isSaving ? !isIncome : isIncome;
              if (countsAsIncome) {
                balance += b.amount;
                // Sobres y ahorros no se muestran en los mini-stats del BalanceCard
                if (!isEnvelope && !isSaving) balanceIncome += b.amount;
              } else {
                balance -= b.amount;
                if (!isEnvelope && !isSaving) balanceExpense += b.amount;
              }
            }

            // ── Estadísticas del mes (excluye ahorros y sobres) ───────────────
            final totalIncome = monthBills
                .where(
                  (b) =>
                      b.cashFlow == 'income' &&
                      !_isSavingMovement(b) &&
                      !_isEnvelopeMovement(b),
                )
                .fold(0.0, (s, b) => s + b.amount);

            final totalExpense = monthBills
                .where(
                  (b) =>
                      b.cashFlow == 'expense' &&
                      !_isSavingMovement(b) &&
                      !_isEnvelopeMovement(b),
                )
                .fold(0.0, (s, b) => s + b.amount);

            // ── Ahorros del mes ───────────────────────────────────────────────
            final savingsDeposits = monthBills
                .where((b) => b.cashFlow == 'income' && _isSavingMovement(b))
                .fold(0.0, (s, b) => s + b.amount);

            final savingsWithdrawals = monthBills
                .where((b) => b.cashFlow == 'expense' && _isSavingMovement(b))
                .fold(0.0, (s, b) => s + b.amount);

            final totalSavings = savingsDeposits - savingsWithdrawals;

            // ── Gastos por categoría (excluye ahorros y sobres) ───────────────
            final expenseBills = monthBills
                .where(
                  (b) =>
                      b.cashFlow == 'expense' &&
                      !_isSavingMovement(b) &&
                      !_isEnvelopeMovement(b),
                )
                .toList();

            final Map<String, _CategoryData> byCategory = {};
            for (final b in expenseBills) {
              final key = b.category.name;
              byCategory[key] = _CategoryData(
                name: key,
                icon: b.category.icon ?? '📦',
                amount: (byCategory[key]?.amount ?? 0) + b.amount,
              );
            }
            final categoryData =
                (byCategory.values.toList()
                      ..sort((a, b) => b.amount.compareTo(a.amount)))
                    .take(4)
                    .toList();

            return RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: () async => context.read<BillsBloc>().add(LoadBills()),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _DashboardHeader(
                      colors: colors,
                      userName: user?.name?.split(' ').first ?? '',
                      month: _month,
                      onPrev: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                      onNext: () {
                        final next = DateTime(_month.year, _month.month + 1);
                        if (!next.isAfter(
                          DateTime(DateTime.now().year, DateTime.now().month),
                        )) {
                          setState(() => _month = next);
                        }
                      },
                      isCurrentMonth:
                          _month.year == DateTime.now().year &&
                          _month.month == DateTime.now().month,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        BalanceCard(
                          colors: colors,
                          balance: balance,
                          income: balanceIncome,
                          expense: balanceExpense,
                        ),
                        const SizedBox(height: 16),
                        MonthStatsRow(
                          colors: colors,
                          income: totalIncome,
                          expense: totalExpense,
                          savings: totalSavings,
                          totalIncome: totalIncome,
                          savingsDeposits: savingsDeposits,
                          savingsWithdrawals: savingsWithdrawals,
                        ),
                        const SizedBox(height: 20),
                        if (categoryData.isNotEmpty) ...[
                          CategoryPieChart(
                            colors: colors,
                            data: categoryData
                                .map(
                                  (c) => CategoryChartData(
                                    name: c.name,
                                    icon: c.icon,
                                    amount: c.amount,
                                    total: totalExpense,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (totalIncome > 0) const SizedBox(height: 16),
                        RecentBillsList(
                          colors: colors,
                          bills: monthBills.take(5).toList(),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final String icon;
  final double amount;
  _CategoryData({required this.name, required this.icon, required this.amount});
}

class _DashboardHeader extends StatelessWidget {
  final AppThemeColors colors;
  final String userName;
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool isCurrentMonth;

  static const _months = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  const _DashboardHeader({
    required this.colors,
    required this.userName,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isNotEmpty ? 'Hola, $userName 👋' : 'Resumen',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onPrev,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Text(
                  '${_months[month.month].substring(0, 3)} ${month.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: isCurrentMonth ? null : onNext,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isCurrentMonth ? colors.border : colors.textPrimary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onRetry;
  const _ErrorView({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
