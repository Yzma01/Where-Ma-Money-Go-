import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

typedef FilterCallback =
    void Function({
      Categories? category,
      Subcategory? subcategory,
      String? month,
      DateTime? fromDate,
      DateTime? toDate,
    });

class FilterSheet extends StatefulWidget {
  final Categories? selectedCategory;
  final Subcategory? selectedSubcategory;
  final String? selectedMonth;
  final DateTime? fromDate;
  final DateTime? toDate;
  final FilterCallback onApply;
  final VoidCallback onClear;

  const FilterSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.selectedMonth,
    required this.fromDate,
    required this.toDate,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  Categories? _category;
  Subcategory? _subcategory;
  String? _month;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _dateMode = 0;

  static const _months = [
    ('1', 'Enero'),
    ('2', 'Febrero'),
    ('3', 'Marzo'),
    ('4', 'Abril'),
    ('5', 'Mayo'),
    ('6', 'Junio'),
    ('7', 'Julio'),
    ('8', 'Agosto'),
    ('9', 'Septiembre'),
    ('10', 'Octubre'),
    ('11', 'Noviembre'),
    ('12', 'Diciembre'),
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _subcategory = widget.selectedSubcategory;
    _month = widget.selectedMonth;
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    if (_month != null) _dateMode = 1;
    if (_fromDate != null || _toDate != null) _dateMode = 2;

    final state = context.read<CategoryBloc>().state;
    if (state is! CategoryLoaded) {
      context.read<CategoryBloc>().add(LoadCategories());
    }
  }

  List<Subcategory> get _subcategories => _category?.subcategories ?? [];

  void _onCategoryTap(Categories? cat) {
    setState(() {
      _category = cat;
      _subcategory = null;
    });
  }

  void _apply() {
    widget.onApply(
      category: _category,
      subcategory: _subcategory,
      month: _dateMode == 1 ? _month : null,
      fromDate: _dateMode == 2 ? _fromDate : null,
      toDate: _dateMode == 2 ? _toDate : null,
    );
    Navigator.pop(context);
  }

  void _clear() {
    widget.onClear();
    Navigator.pop(context);
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final colors = context.read<ThemeProvider>().colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.primary,
            surface: colors.surface,
            onSurface: colors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + título fijos
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Filtrar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clear,
                      child: Text(
                        'Limpiar todo',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Contenido scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Categoría — Wrap sin scroll
                  _SectionLabel(text: 'CATEGORÍA', colors: colors),
                  const SizedBox(height: 10),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      if (state is CategoryLoading) {
                        return SizedBox(
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final categories = state is CategoryLoaded
                          ? state.categories
                          : <Categories>[];

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            icon: '🗂️',
                            selected: _category == null,
                            colors: colors,
                            onTap: () => _onCategoryTap(null),
                          ),
                          ...categories.map(
                            (cat) => _FilterChip(
                              label: cat.name,
                              icon: cat.icon ?? '📦',
                              selected: _category?.name == cat.name,
                              colors: colors,
                              onTap: () => _onCategoryTap(cat),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Subcategoría — Wrap sin scroll
                  if (_category != null && _subcategories.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(text: 'SUBCATEGORÍA', colors: colors),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Todas',
                          icon: '•',
                          isEmoji: false,
                          selected: _subcategory == null,
                          colors: colors,
                          onTap: () => setState(() => _subcategory = null),
                        ),
                        ..._subcategories.map(
                          (sub) => _FilterChip(
                            label: sub.name,
                            icon: '•',
                            isEmoji: false,
                            selected: _subcategory?.name == sub.name,
                            colors: colors,
                            onTap: () => setState(() => _subcategory = sub),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Fecha
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'FECHA', colors: colors),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _ModeButton(
                        label: 'Sin filtro',
                        selected: _dateMode == 0,
                        colors: colors,
                        onTap: () => setState(() {
                          _dateMode = 0;
                          _month = null;
                          _fromDate = null;
                          _toDate = null;
                        }),
                      ),
                      _ModeButton(
                        label: 'Por mes',
                        selected: _dateMode == 1,
                        colors: colors,
                        onTap: () => setState(() {
                          _dateMode = 1;
                          _fromDate = null;
                          _toDate = null;
                        }),
                      ),
                      _ModeButton(
                        label: 'Rango',
                        selected: _dateMode == 2,
                        colors: colors,
                        onTap: () => setState(() {
                          _dateMode = 2;
                          _month = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Meses — Wrap sin scroll
                  if (_dateMode == 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _months.map((entry) {
                        final (value, name) = entry;
                        final selected = _month == value;
                        return GestureDetector(
                          onTap: () => setState(() => _month = value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary
                                  : colors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? colors.primary
                                    : colors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : colors.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Rango de fechas
                  if (_dateMode == 2)
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'Desde',
                            date: _fromDate,
                            colors: colors,
                            onTap: () => _pickDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateButton(
                            label: 'Hasta',
                            date: _toDate,
                            colors: colors,
                            onTap: () => _pickDate(context, false),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Aplicar filtros',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _SectionLabel({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: colors.textSecondary,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isEmoji;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.isEmoji = true,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEmoji)
              Text(icon, style: const TextStyle(fontSize: 14))
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate ? colors.primary.withOpacity(0.1) : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate ? colors.primary.withOpacity(0.4) : colors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasDate ? colors.primary : colors.iconDefault,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasDate
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Seleccionar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasDate ? colors.primary : colors.textSecondary,
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
