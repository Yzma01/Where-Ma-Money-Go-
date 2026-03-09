import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/screens/add_bill.dart';
import 'package:where_ma_money_go/widgets/bills/filter.dart';
import 'package:where_ma_money_go/widgets/bills/bill_card.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  // ── Filtros activos
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedMonth; // formato 'M' (número de mes como string)
  Categories? _selectedCategory;
  Subcategory? _selectedSubcategory;
  Saving? _selectedSaving; // ← nuevo filtro de meta de ahorro

  @override
  void initState() {
    super.initState();
    context.read<BillsBloc>().add(LoadBills());
  }

  List<Bill> _applyFilters(List<Bill> bills) {
    return bills.where((bill) {
      // Filtro por categoría
      if (_selectedCategory != null &&
          bill.category.name != _selectedCategory!.name) {
        return false;
      }

      if (_selectedSubcategory != null &&
          bill.subcategory.name != _selectedSubcategory!.name) {
        return false;
      }

      final date = bill.date ?? DateTime.now();

      // Filtro por mes específico (dropdown rápido)
      if (_selectedMonth != null && _fromDate == null && _toDate == null) {
        if (bill.month != _selectedMonth) return false;
      }

      // Filtro por rango de fechas
      if (_fromDate != null) {
        final from = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
        );
        if (date.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(
          _toDate!.year,
          _toDate!.month,
          _toDate!.day,
          23,
          59,
          59,
        );
        if (date.isAfter(to)) return false;
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedMonth != null ||
      _fromDate != null ||
      _toDate != null ||
      _selectedSubcategory != null;

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedMonth != null || _fromDate != null || _toDate != null) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedMonth = null;
      _selectedCategory = null;
      _selectedSubcategory = null;
    });
  }

  void _openFilterSheet(BuildContext context, List<Categories> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        selectedCategory: _selectedCategory,
        selectedSubcategory: _selectedSubcategory, // ← nuevo
        selectedMonth: _selectedMonth,
        fromDate: _fromDate,
        toDate: _toDate,
        selectedSaving: _selectedSaving, // ← nuevo
        onApply: ({category, subcategory, month, fromDate, toDate, saving}) {
          // ← subcategory nuevo
          setState(() {
            _selectedCategory = category;
            _selectedSaving = saving;
            _selectedSubcategory = subcategory; // ← nuevo
            _selectedMonth = month;
            _fromDate = fromDate;
            _toDate = toDate;
          });
        },
        onClear: _clearFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

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
              return _ErrorView(colors: colors, message: state.message);
            }

            final allBills = state is BillsLoaded ? state.bills : <Bill>[];
            final filtered = _applyFilters(allBills);

            // Categorías únicas para el filtro
            final categories = allBills.map((b) => b.category).toSet().toList();

            return Column(
              children: [
                _Header(
                  colors: colors,
                  filterCount: _activeFilterCount,
                  onFilter: () => _openFilterSheet(context, categories),
                ),
                if (_hasActiveFilters)
                  _ActiveFiltersBar(
                    colors: colors,
                    selectedCategory: _selectedCategory,
                    selectedSubcategory: _selectedSubcategory, // ← nuevo
                    selectedMonth: _selectedMonth,
                    fromDate: _fromDate,
                    toDate: _toDate,
                    onClear: _clearFilters,
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyView(
                          colors: colors,
                          hasFilters: _hasActiveFilters,
                          onClear: _clearFilters,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              BillCard(bill: filtered[i], colors: colors),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddBillScreen()),
        ),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nuevo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppThemeColors colors;
  final int filterCount;
  final VoidCallback onFilter;

  const _Header({
    required this.colors,
    required this.filterCount,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 12),
      child: Row(
        children: [
          Text(
            'Movimientos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onFilter,
                icon: Icon(Icons.tune_rounded, color: colors.textPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colors.border, width: 0.5),
                ),
              ),
              if (filterCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Active Filters Bar ───────────────────────────────────────────────────────

class _ActiveFiltersBar extends StatelessWidget {
  final AppThemeColors colors;
  final Categories? selectedCategory;
  final Subcategory? selectedSubcategory; // ← nuevo
  final String? selectedMonth;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onClear;

  const _ActiveFiltersBar({
    required this.colors,
    required this.selectedCategory,
    required this.selectedSubcategory, // ← nuevo
    required this.selectedMonth,
    required this.fromDate,
    required this.toDate,
    required this.onClear,
  });

  static const _monthNames = [
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

  String _dateLabel() {
    if (fromDate != null && toDate != null) {
      return '${fromDate!.day}/${fromDate!.month} – ${toDate!.day}/${toDate!.month}';
    }
    if (fromDate != null) return 'Desde ${fromDate!.day}/${fromDate!.month}';
    if (toDate != null) return 'Hasta ${toDate!.day}/${toDate!.month}';
    if (selectedMonth != null) {
      return _monthNames[int.tryParse(selectedMonth!) ?? 0];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (selectedCategory != null)
                  _Chip(
                    label: selectedCategory!.name,
                    icon: selectedCategory!.icon ?? '📦',
                    colors: colors,
                  ),
                if (selectedSubcategory != null) // ← nuevo chip
                  _Chip(
                    label: selectedSubcategory!.name,
                    icon: '•',
                    isEmoji: false,
                    colors: colors,
                  ),
                if (dateLabel.isNotEmpty)
                  _Chip(label: dateLabel, icon: '📅', colors: colors),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Limpiar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isEmoji;
  final AppThemeColors colors;

  const _Chip({
    required this.label,
    required this.icon,
    this.isEmoji = true,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmoji)
            Text(icon, style: const TextStyle(fontSize: 12))
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final AppThemeColors colors;
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyView({
    required this.colors,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.filter_list_off_rounded
                : Icons.receipt_long_outlined,
            size: 52,
            color: colors.iconDefault,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'Sin resultados' : 'Sin movimientos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Prueba cambiando los filtros'
                : 'Agrega tu primer movimiento',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Limpiar filtros',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final AppThemeColors colors;
  final String message;

  const _ErrorView({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<BillsBloc>().add(LoadBills()),
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
      ),
    );
  }
}
