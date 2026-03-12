import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/note_priority.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/services/notifications/notes/service.dart';
import 'package:where_ma_money_go/widgets/notes/chip.dart';
import 'package:where_ma_money_go/widgets/notes/field.dart';
import 'package:where_ma_money_go/widgets/notes/label.dart';
import 'package:where_ma_money_go/widgets/notes/segment_row.dart';
import 'package:where_ma_money_go/widgets/notes/title.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class NoteSheet extends StatefulWidget {
  final AppThemeColors colors;
  final Note? note;

  const NoteSheet({super.key, required this.colors, this.note});

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _amountCtrl;
  late bool _isRecurrent;
  late bool _hasBill;
  late bool _hasDueDate;
  late bool _isCompleted;
  late DateTime _dueDate;
  late NotePriority _priority;
  late String _noteCategory; // categoría de nota (de BD, tipo "notas")
  String _frequency = 'monthly';
  String _cashFlow = 'expense';
  Categories? _billCategory; // categoría del bill
  Subcategory? _subcategory;
  Saving? _selectedSaving;

  bool get _isEditing => widget.note != null;
  bool get _isAhorro =>
      _billCategory?.name.toLowerCase().contains('ahorro') ?? false;
  List<Subcategory> get _subs => _billCategory?.subcategories ?? [];

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _contentCtrl = TextEditingController(text: n?.content ?? '');
    _amountCtrl = TextEditingController(
      text: n?.bill?.amount.toStringAsFixed(0) ?? '',
    );
    _isRecurrent = n?.isRecurrent ?? false;
    _hasBill = n?.hasBill ?? false;
    _hasDueDate = n?.hasDueDate ?? false;
    _isCompleted = n?.isCompleted ?? false;
    _dueDate = n?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _priority = n?.priority ?? NotePriority.none;
    _noteCategory = n?.category ?? '';
    _frequency = n?.recurrent?.frequency ?? 'monthly';
    _cashFlow = n?.bill?.cashFlow ?? 'expense';

    if (context.read<CategoryBloc>().state is! CategoryLoaded) {
      context.read<CategoryBloc>().add(LoadCategories());
    }
    if (context.read<SavingBloc>().state is! SavingLoaded) {
      context.read<SavingBloc>().add(LoadSavings());
    }

    // Resolver billCategory fresca del bloc
    if (n?.bill?.category != null) {
      final savedName = n!.bill!.category.name;
      final catState = context.read<CategoryBloc>().state;
      if (catState is CategoryLoaded) {
        _billCategory = catState.categories.firstWhere(
          (c) => c.name == savedName,
          orElse: () => n.bill!.category,
        );
        if (n.bill?.subcategory != null) {
          final savedSub = n.bill!.subcategory.name;
          _subcategory = _billCategory?.subcategories?.firstWhere(
            (s) => s.name == savedSub,
            orElse: () => n.bill!.subcategory,
          );
        }
      } else {
        _billCategory = n.bill!.category;
        _subcategory = n.bill?.subcategory;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    Bill? bill;
    if (_hasBill && _billCategory != null) {
      final amount =
          double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
      if (amount > 0) {
        final sub = _isAhorro && _selectedSaving != null
            ? Subcategory(name: _selectedSaving!.name)
            : _subcategory ?? Subcategory(name: _billCategory!.name);
        bill = Bill(
          id: widget.note?.bill?.id ?? const Uuid().v4(),
          category: _billCategory!,
          subcategory: sub,
          amount: amount,
          date: DateTime.now(),
          month: DateTime.now().month.toString(),
          type: 'fixed',
          cashFlow: _cashFlow,
          savingId: _isAhorro ? _selectedSaving?.id : null,
        );
      }
    }

    Recurrent? recurrent;
    if (_isRecurrent) {
      recurrent = Recurrent(
        id: widget.note?.recurrent?.id ?? const Uuid().v4(),
        title: title,
        startDate: widget.note?.createdAt ?? DateTime.now(),
        frequency: _frequency,
        nextDueDate: widget.note?.recurrent?.nextDueDate,
      );
    }

    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: title,
      content: _contentCtrl.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      dueDate: _hasDueDate ? _dueDate : null,
      category: _noteCategory,
      hasDueDate: _hasDueDate,
      hasBill: _hasBill && bill != null,
      priority: _priority,
      bill: bill,
      isRecurrent: _isRecurrent,
      isCompleted: _isCompleted,
      recurrent: recurrent,
    );

    if (_isEditing) {
      context.read<NotesBloc>().add(UpdateNote(note: note));
    } else {
      context.read<NotesBloc>().add(AddNote(note: note));
    }
    // Programar notificaciones para esta nota
    NotificationService.instance.scheduleForNote(note);
    Navigator.pop(context);
  }

  Future<void> _pickDueDate() async {
    final colors = widget.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            colors: colors,
            isEditing: _isEditing,
            isCompleted: _isCompleted,
            onToggleComplete: () =>
                setState(() => _isCompleted = !_isCompleted),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Título ─────────────────────────────────────────────
                  SheetLabel('TÍTULO', colors),
                  const SizedBox(height: 8),
                  SheetField(
                    ctrl: _titleCtrl,
                    colors: colors,
                    hint: 'Nombre...',
                    maxLines: 1,
                    fontSize: 16,
                    bold: true,
                  ),
                  const SizedBox(height: 16),

                  // ── Descripción ────────────────────────────────────────
                  SheetLabel('DESCRIPCIÓN', colors),
                  const SizedBox(height: 8),
                  SheetField(
                    ctrl: _contentCtrl,
                    colors: colors,
                    hint: 'Notas...',
                    maxLines: 3,
                    fontSize: 14,
                    bold: false,
                  ),
                  const SizedBox(height: 20),

                  // ── Categoría de nota ───────────────────────────────────
                  SheetLabel('CATEGORÍA', colors),
                  const SizedBox(height: 8),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (_, state) {
                      // Solo mostrar subcategorías de tipo "notas"
                      final noteCats = state is CategoryLoaded
                          ? state.categories
                                .where(
                                  (c) =>
                                      c.name.toLowerCase().contains('nota') ||
                                      (c.subcategories?.any((s) => true) ??
                                          false),
                                )
                                .expand(
                                  (c) => [
                                    // La propia categoría "Notas" como opción
                                    if (c.name.toLowerCase().contains('nota'))
                                      c.name,
                                    // Subcategorías de cualquier categoría marcada
                                    ...(c.subcategories
                                            ?.map((s) => s.name)
                                            .toList() ??
                                        []),
                                  ],
                                )
                                .toSet()
                                .toList()
                          : <String>[];

                      // Filtrar: solo subcategorías de categorías cuyo nombre sea "notas"
                      final noteCategories = state is CategoryLoaded
                          ? _buildNoteCategories(state.categories)
                          : <String>[];

                      if (noteCategories.isEmpty && state is CategoryLoaded) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'No hay categorías de notas. Crea una categoría llamada "Notas" en Ajustes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Opción "Sin categoría"
                          GestureDetector(
                            onTap: () => setState(() => _noteCategory = ''),
                            child: SheetChip(
                              label: 'Sin categoría',
                              icon: '🏷️',
                              selected: _noteCategory.isEmpty,
                              colors: colors,
                            ),
                          ),
                          ...noteCategories.map(
                            (name) => GestureDetector(
                              onTap: () => setState(() => _noteCategory = name),
                              child: SheetChip(
                                label: name,
                                icon: '•',
                                isEmoji: false,
                                selected: _noteCategory == name,
                                colors: colors,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Prioridad ──────────────────────────────────────────
                  SheetLabel('PRIORIDAD', colors),
                  const SizedBox(height: 8),
                  _PriorityPicker(
                    colors: colors,
                    selected: _priority,
                    onChanged: (p) => setState(() => _priority = p),
                  ),
                  const SizedBox(height: 20),

                  // ── Fecha de caducidad ─────────────────────────────────
                  SheetSwitchTile(
                    colors: colors,
                    icon: Icons.access_time_rounded,
                    label: 'Fecha de caducidad',
                    subtitle: 'Recibe una alerta cuando venza',
                    value: _hasDueDate,
                    onChanged: (v) => setState(() => _hasDueDate = v),
                  ),
                  if (_hasDueDate) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_dueDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: colors.iconDefault,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Recurrente ─────────────────────────────────────────
                  SheetSwitchTile(
                    colors: colors,
                    icon: Icons.repeat_rounded,
                    label: 'Recurrente',
                    subtitle: 'Aparece en "Pagos recurrentes"',
                    value: _isRecurrent,
                    onChanged: (v) => setState(() => _isRecurrent = v),
                  ),
                  if (_isRecurrent) ...[
                    const SizedBox(height: 14),
                    SheetLabel('FRECUENCIA', colors),
                    const SizedBox(height: 8),
                    _FrequencyPicker(
                      colors: colors,
                      selected: _frequency,
                      onChanged: (v) => setState(() => _frequency = v),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Pago fijo ──────────────────────────────────────────
                  SheetSwitchTile(
                    colors: colors,
                    icon: Icons.receipt_long_outlined,
                    label: 'Pago fijo asociado',
                    subtitle: 'Al marcar como pagada se registra el movimiento',
                    value: _hasBill,
                    onChanged: (v) => setState(() => _hasBill = v),
                  ),
                  if (_hasBill) ...[
                    const SizedBox(height: 16),
                    SheetLabel('TIPO', colors),
                    const SizedBox(height: 8),
                    SheetSegmentedRow(
                      colors: colors,
                      options: const [
                        ('expense', '↑ Egreso'),
                        ('income', '↓ Ingreso'),
                      ],
                      selected: _cashFlow,
                      onChanged: (v) => setState(() => _cashFlow = v),
                    ),
                    const SizedBox(height: 14),
                    SheetLabel('MONTO', colors),
                    const SizedBox(height: 8),
                    SheetField(
                      ctrl: _amountCtrl,
                      colors: colors,
                      hint: '0',
                      maxLines: 1,
                      fontSize: 22,
                      bold: true,
                      keyboardType: TextInputType.number,
                      prefix: '\u20a1 ',
                      accentColor: _cashFlow == 'expense'
                          ? colors.error
                          : colors.success,
                    ),
                    const SizedBox(height: 14),
                    SheetLabel('CATEGORÍA DEL GASTO', colors),
                    const SizedBox(height: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (_, state) {
                        if (state is CategoryLoading) {
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          );
                        }
                        final cats = state is CategoryLoaded
                            ? state.categories
                            : <Categories>[];

                        if (_billCategory != null &&
                            (_billCategory!.subcategories == null ||
                                _billCategory!.subcategories!.isEmpty) &&
                            state is CategoryLoaded) {
                          final fresh = cats.firstWhere(
                            (c) => c.name == _billCategory!.name,
                            orElse: () => _billCategory!,
                          );
                          if (fresh.subcategories?.isNotEmpty == true) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted)
                                setState(() => _billCategory = fresh);
                            });
                          }
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cats
                              .map(
                                (cat) => GestureDetector(
                                  onTap: () => setState(() {
                                    _billCategory = cat;
                                    _subcategory = null;
                                    _selectedSaving = null;
                                  }),
                                  child: SheetChip(
                                    label: cat.name,
                                    icon: cat.icon ?? '📦',
                                    selected: _billCategory?.name == cat.name,
                                    colors: colors,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),

                    // Planes de ahorro si cat = Ahorro
                    if (_isAhorro) ...[
                      const SizedBox(height: 14),
                      SheetLabel('PLAN DE AHORRO', colors),
                      const SizedBox(height: 8),
                      BlocBuilder<SavingBloc, SavingState>(
                        builder: (_, state) {
                          final allSavings = state is SavingLoaded
                              ? state.savings
                                    .where((s) => s.isNotEmpty)
                                    .toList()
                              : <Saving>[];

                          if (allSavings.isEmpty) {
                            return _EmptySavingsHint(colors: colors);
                          }

                          return Column(
                            children: allSavings
                                .map(
                                  (s) => _SavingPlanTile(
                                    saving: s,
                                    colors: colors,
                                    selected: _selectedSaving?.id == s.id,
                                    onTap: () => setState(() {
                                      _selectedSaving =
                                          _selectedSaving?.id == s.id
                                          ? null
                                          : s;
                                      if (_selectedSaving != null) {
                                        final rem =
                                            s.goalAmount - s.currentAmount;
                                        if (rem > 0 &&
                                            _amountCtrl.text.isEmpty) {
                                          _amountCtrl.text = rem
                                              .toStringAsFixed(0);
                                        }
                                      }
                                    }),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],

                    // Subcategorías si cat normal
                    if (!_isAhorro &&
                        _billCategory != null &&
                        _subs.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SheetLabel('SUBCATEGORÍA', colors),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subs
                            .map(
                              (sub) => GestureDetector(
                                onTap: () => setState(() => _subcategory = sub),
                                child: SheetChip(
                                  label: sub.name,
                                  icon: '•',
                                  isEmoji: false,
                                  selected: _subcategory?.name == sub.name,
                                  colors: colors,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEditing ? 'Guardar cambios' : 'Crear nota',
                        style: const TextStyle(
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

  /// Devuelve los nombres de subcategorías de la categoría "Notas"
  /// o el nombre de la categoría si no tiene subs.
  List<String> _buildNoteCategories(List<Categories> allCats) {
    final result = <String>[];
    for (final cat in allCats) {
      if (!cat.name.toLowerCase().contains('nota')) continue;
      final subs = cat.subcategories ?? [];
      if (subs.isEmpty) {
        result.add(cat.name);
      } else {
        result.addAll(subs.map((s) => s.name));
      }
    }
    return result;
  }

  static const _monthsShort = [
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

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthsShort[d.month]} ${d.year}';
}

// ─── Priority Picker ─────────────────────────────────────────────────────────

class _PriorityPicker extends StatelessWidget {
  final AppThemeColors colors;
  final NotePriority selected;
  final ValueChanged<NotePriority> onChanged;

  const _PriorityPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  Color _colorFor(NotePriority p, AppThemeColors c) {
    switch (p) {
      case NotePriority.high:
        return c.error;
      case NotePriority.medium:
        return c.warning;
      case NotePriority.low:
        return c.success;
      case NotePriority.none:
        return c.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: NotePriority.values.map((p) {
        final sel = selected == p;
        final color = _colorFor(p, colors);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: p != NotePriority.high ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? color : colors.border,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    p.emoji.isNotEmpty ? p.emoji : '—',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: sel ? color : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Saving plan tile ─────────────────────────────────────────────────────────

class _SavingPlanTile extends StatelessWidget {
  final Saving saving;
  final AppThemeColors colors;
  final bool selected;
  final VoidCallback onTap;

  const _SavingPlanTile({
    required this.saving,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = saving;
    final progress = s.goalAmount > 0
        ? (s.currentAmount / s.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (s.goalAmount - s.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final daysLeft = s.dueDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(0.08) : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress,
                  color: selected ? colors.primary : colors.textSecondary,
                  trackColor: (selected ? colors.primary : colors.textSecondary)
                      .withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Falta \u20a1${remaining.toStringAsFixed(0)} · ${daysLeft > 0 ? '$daysLeft días' : 'Vencida'}',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptySavingsHint extends StatelessWidget {
  final AppThemeColors colors;
  const _EmptySavingsHint({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Text('🐷', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No tienes planes de ahorro activos.\nCrea uno en la pantalla de Ahorros.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet Header ─────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final AppThemeColors colors;
  final bool isEditing;
  final bool isCompleted;
  final VoidCallback onToggleComplete;

  const _SheetHeader({
    required this.colors,
    required this.isEditing,
    required this.isCompleted,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Column(
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                isEditing ? 'Editar nota' : 'Nueva nota',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isEditing)
                GestureDetector(
                  onTap: onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? colors.success.withOpacity(0.12)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? colors.success : colors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: isCompleted
                              ? colors.success
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isCompleted ? 'Completada' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? colors.success
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Frequency Picker ─────────────────────────────────────────────────────────

class _FrequencyPicker extends StatelessWidget {
  final AppThemeColors colors;
  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('daily', 'Diario'),
    ('weekly', 'Semanal'),
    ('monthly', 'Mensual'),
    ('yearly', 'Anual'),
  ];

  const _FrequencyPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((f) {
        final sel = selected == f.$1;
        return GestureDetector(
          onTap: () => onChanged(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? colors.primary : colors.border,
                width: sel ? 1.5 : 0.5,
              ),
            ),
            child: Text(
              f.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
