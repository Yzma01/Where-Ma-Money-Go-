import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _cashFlow = 'expense'; // 'expense' | 'income'
  String _type = 'variable'; // 'variable' | 'fixed'
  Categories? _selectedCategory;
  Subcategory? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final state = context.read<CategoryBloc>().state;
    if (state is! CategoryLoaded) {
      context.read<CategoryBloc>().add(LoadCategories());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<Subcategory> get _subcategories =>
      _selectedCategory?.subcategories ?? [];

  Future<void> _pickDate() async {
    final colors = context.read<ThemeProvider>().colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      _showError('Selecciona una categoría');
      return;
    }
    if (_subcategories.isNotEmpty && _selectedSubcategory == null) {
      _showError('Selecciona una subcategoría');
      return;
    }

    final bill = Bill(
      category: _selectedCategory!,
      subcategory:
          _selectedSubcategory ?? Subcategory(name: _selectedCategory!.name),
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      date: _selectedDate,
      month: _selectedDate.month.toString(),
      type: _type,
      cashFlow: _cashFlow,
    );

    context.read<BillsBloc>().add(AddBill(bill: bill));
    Navigator.pop(context);
  }

  void _showError(String msg) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(colors: colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tipo de flujo (egreso / ingreso)
                      _CashFlowToggle(
                        colors: colors,
                        value: _cashFlow,
                        onChanged: (v) => setState(() => _cashFlow = v),
                      ),
                      const SizedBox(height: 28),

                      // ── Monto
                      _SectionLabel(text: 'MONTO', colors: colors),
                      const SizedBox(height: 10),
                      _AmountField(
                        controller: _amountController,
                        colors: colors,
                        cashFlow: _cashFlow,
                      ),
                      const SizedBox(height: 24),

                      // ── Fecha
                      _SectionLabel(text: 'FECHA', colors: colors),
                      const SizedBox(height: 10),
                      _DateSelector(
                        colors: colors,
                        date: _selectedDate,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 24),

                      // ── Tipo (variable / fijo)
                      _SectionLabel(text: 'TIPO', colors: colors),
                      const SizedBox(height: 10),
                      _SegmentedPicker(
                        colors: colors,
                        options: const [
                          ('variable', 'Variable'),
                          ('fixed', 'Fijo'),
                        ],
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 24),

                      // ── Categoría desde BLoC
                      _SectionLabel(text: 'CATEGORÍA', colors: colors),
                      const SizedBox(height: 10),
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, state) {
                          if (state is CategoryLoading) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
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
                            children: categories.map((cat) {
                              final selected =
                                  _selectedCategory?.name == cat.name;
                              return _SelectableChip(
                                label: cat.name,
                                icon: cat.icon ?? '📦',
                                selected: selected,
                                colors: colors,
                                onTap: () => setState(() {
                                  _selectedCategory = cat;
                                  _selectedSubcategory = null;
                                }),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      // ── Subcategoría (condicional)
                      if (_selectedCategory != null &&
                          _subcategories.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionLabel(text: 'SUBCATEGORÍA', colors: colors),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _subcategories.map((sub) {
                            final selected =
                                _selectedSubcategory?.name == sub.name;
                            return _SelectableChip(
                              label: sub.name,
                              icon: '•',
                              isEmoji: false,
                              selected: selected,
                              colors: colors,
                              onTap: () =>
                                  setState(() => _selectedSubcategory = sub),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 36),

                      // ── Botón guardar
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cashFlow == 'expense'
                                ? colors.error
                                : colors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _cashFlow == 'expense'
                                ? 'Registrar egreso'
                                : 'Registrar ingreso',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppThemeColors colors;
  const _TopBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
          Text(
            'Nuevo movimiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cash Flow Toggle ─────────────────────────────────────────────────────────

class _CashFlowToggle extends StatelessWidget {
  final AppThemeColors colors;
  final String value;
  final ValueChanged<String> onChanged;

  const _CashFlowToggle({
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Egreso',
            icon: Icons.arrow_upward_rounded,
            selected: value == 'expense',
            selectedColor: colors.error,
            colors: colors,
            onTap: () => onChanged('expense'),
          ),
          _ToggleOption(
            label: 'Ingreso',
            icon: Icons.arrow_downward_rounded,
            selected: value == 'income',
            selectedColor: colors.success,
            colors: colors,
            onTap: () => onChanged('income'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Amount Field ─────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final AppThemeColors colors;
  final String cashFlow;

  const _AmountField({
    required this.controller,
    required this.colors,
    required this.cashFlow,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = cashFlow == 'expense' ? colors.error : colors.success;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: accentColor,
      ),
      textAlign: TextAlign.center,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa un monto';
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Monto inválido';
        return null;
      },
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          color: accentColor.withOpacity(0.3),
        ),
        prefixText: '\₡ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: accentColor.withOpacity(0.6),
        ),
        filled: true,
        fillColor: accentColor.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}

// ─── Date Selector ────────────────────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  final AppThemeColors colors;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.colors,
    required this.date,
    required this.onTap,
  });

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

  String _isToday() {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return ' · Hoy';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '${_weekdays[date.weekday]} ${date.day} ${_months[date.month]} ${date.year}${_isToday()}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: colors.iconDefault),
          ],
        ),
      ),
    );
  }
}

// ─── Segmented Picker ─────────────────────────────────────────────────────────

class _SegmentedPicker extends StatelessWidget {
  final AppThemeColors colors;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedPicker({
    required this.colors,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((opt) {
          final (value, label) = opt;
          final isSelected = selected == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Selectable Chip ──────────────────────────────────────────────────────────

class _SelectableChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isEmoji;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _SelectableChip({
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

// ─── Section Label ────────────────────────────────────────────────────────────

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
