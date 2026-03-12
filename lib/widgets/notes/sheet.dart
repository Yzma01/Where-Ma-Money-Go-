import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/screens/add_bill.dart';
import 'package:where_ma_money_go/widgets/notes/chip.dart';
import 'package:where_ma_money_go/widgets/notes/field.dart';
import 'package:where_ma_money_go/widgets/notes/label.dart';
import 'package:where_ma_money_go/widgets/notes/segment_row.dart';
import 'package:where_ma_money_go/widgets/notes/title.dart';

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
  late bool _isCompleted;
  String _frequency = 'monthly';
  String _cashFlow = 'expense';
  Categories? _category;
  Subcategory? _subcategory;

  bool get _isEditing => widget.note != null;
  List<Subcategory> get _subs => _category?.subcategories ?? [];

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
    _isCompleted = n?.isCompleted ?? false;
    _frequency = n?.recurrent?.frequency ?? 'monthly';
    _cashFlow = n?.bill?.cashFlow ?? 'expense';

    // Cargar categorías si no están
    final catState = context.read<CategoryBloc>().state;
    if (catState is! CategoryLoaded) {
      context.read<CategoryBloc>().add(LoadCategories());
    }

    // ✅ Buscar la categoría completa (con subcategorías) en el bloc,
    //    en lugar de usar la versión embebida en el bill (que viene sin subs)
    if (n?.bill?.category != null) {
      final savedCatName = n!.bill!.category.name;
      if (catState is CategoryLoaded) {
        _category = catState.categories.firstWhere(
          (c) => c.name == savedCatName,
          orElse: () => n.bill!.category,
        );
        // Buscar subcategoría guardada dentro de las subs de la categoría fresca
        if (n.bill?.subcategory != null) {
          final savedSubName = n.bill!.subcategory.name;
          _subcategory = _category?.subcategories?.firstWhere(
            (s) => s.name == savedSubName,
            orElse: () => n.bill!.subcategory,
          );
        }
      } else {
        // El bloc aún no cargó — guardar nombre para resolver después
        _category = n.bill!.category;
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
    if (_hasBill && _category != null) {
      final amount =
          double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
      if (amount > 0) {
        bill = Bill(
          id: widget.note?.bill?.id ?? const Uuid().v4(),
          category: _category!,
          subcategory: _subcategory ?? Subcategory(name: _category!.name),
          amount: amount,
          date: DateTime.now(),
          month: DateTime.now().month.toString(),
          type: 'fixed',
          cashFlow: _cashFlow,
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
      );
    }

    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: title,
      content: _contentCtrl.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      hasBill: _hasBill && bill != null,
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                    SheetLabel('CATEGORÍA', colors),
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

                        // ✅ Si la categoría cargada aún no tiene subcategorías (vino del bill embebido),
                        //    resolverla ahora con la lista fresca del bloc
                        if (_category != null &&
                            (_category!.subcategories == null ||
                                _category!.subcategories!.isEmpty) &&
                            state is CategoryLoaded) {
                          final fresh = cats.firstWhere(
                            (c) => c.name == _category!.name,
                            orElse: () => _category!,
                          );
                          if (fresh.subcategories?.isNotEmpty == true) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _category = fresh);
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
                                    _category =
                                        cat; // ← siempre usa el objeto fresco del bloc
                                    _subcategory = null;
                                  }),
                                  child: SheetChip(
                                    label: cat.name,
                                    icon: cat.icon ?? '📦',
                                    selected: _category?.name == cat.name,
                                    colors: colors,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    if (_category?.name.toLowerCase() == 'ahorro') ...[
                      const SizedBox(height: 14),
                      SheetLabel('METAS DE AHORRO', colors),
                      const SizedBox(height: 8),
                      BlocBuilder<SavingBloc, SavingState>(
                        builder: (context, state) {
                          if (state is SavingLoading) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              ),
                            );
                          }

                          final activeSavings = state is SavingLoaded
                              ? state.savings
                                    .where((s) => !s.isCompleted)
                                    .toList()
                              : <Saving>[];

                          if (activeSavings.isEmpty) {
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
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No hay metas activas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: activeSavings.map((s) {
                              final progress = s.goalAmount > 0
                                  ? (s.currentAmount / s.goalAmount).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0.0;
                              final selected = _subcategory?.name == s.name;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  // Guardamos la meta seleccionada usando el campo de subcategoría
                                  _subcategory = Subcategory(name: s.name);
                                }),
                                child: SavingChip(
                                  saving: s,
                                  progress: progress,
                                  selected: selected,
                                  colors: colors,
                                  onTap: () => setState(() {
                                    _subcategory = Subcategory(name: s.name);
                                  }),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                    if (_category != null && _subs.isNotEmpty) ...[
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
}

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
