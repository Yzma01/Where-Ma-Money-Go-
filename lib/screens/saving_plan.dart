import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/saving.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class SavingPlan extends StatefulWidget {
  const SavingPlan({super.key});

  @override
  State<SavingPlan> createState() => _SavingPlanState();
}

class _SavingPlanState extends State<SavingPlan> {
  @override
  void initState() {
    super.initState();
    context.read<SavingBloc>().add(LoadSavings());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<SavingBloc, SavingState>(
          builder: (context, state) {
            if (state is SavingLoading) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.primary,
                ),
              );
            }

            if (state is SavingError) {
              return _ErrorView(
                colors: colors,
                onRetry: () => context.read<SavingBloc>().add(LoadSavings()),
              );
            }
            final savings = state is SavingLoaded ? state.savings : <Saving>[];
            savings.sort((a, b) {
              if (a.isCompleted != b.isCompleted) {
                return a.isCompleted ? 1 : -1;
              }
              return a.dueDate.compareTo(b.dueDate);
            });
            return Column(
              children: [
                _Header(
                  colors: colors,
                  onAdd: () => _openSheet(context, colors),
                ),
                Expanded(
                  child: savings.isEmpty
                      ? _EmptyState(
                          colors: colors,
                          onAdd: () => _openSheet(context, colors),
                        )
                      : _SavingsList(colors: colors, savings: savings),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openSheet(
    BuildContext context,
    AppThemeColors colors, [
    Saving? saving,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SavingBloc>(),
        child: _SavingSheet(colors: colors, saving: saving),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAdd;

  const _Header({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 16),
      child: Row(
        children: [
          Text(
            'Metas de ahorro',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, color: colors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista ────────────────────────────────────────────────────────────────────

class _SavingsList extends StatelessWidget {
  final AppThemeColors colors;
  final List<Saving> savings;

  const _SavingsList({required this.colors, required this.savings});

  @override
  Widget build(BuildContext context) {
    final completed = savings.where((s) => s.isCompleted).length;
    final totalGoal = savings.fold(0.0, (s, v) => s + v.goalAmount);
    final totalCurrent = savings.fold(0.0, (s, v) => s + v.currentAmount);

    return CustomScrollView(
      slivers: [
        // Resumen general
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _SummaryCard(
              colors: colors,
              totalGoal: totalGoal,
              totalCurrent: totalCurrent,
              completed: completed,
              total: savings.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SavingCard(
                  colors: colors,
                  saving: savings[i],
                  onEdit: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<SavingBloc>(),
                      child: _SavingSheet(colors: colors, saving: savings[i]),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, savings[i]),
                ),
              ),
              childCount: savings.length,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Saving saving) {
    final colors = context.read<ThemeProvider>().colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar meta',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '¿Eliminar "${saving.name}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint('Deleting saving with id: ${saving.id}');
              context.read<SavingBloc>().add(DeleteSaving(id: saving.id));
              Navigator.pop(context);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatefulWidget {
  final AppThemeColors colors;
  final double totalGoal;
  final double totalCurrent;
  final int completed;
  final int total;

  const _SummaryCard({
    required this.colors,
    required this.totalGoal,
    required this.totalCurrent,
    required this.completed,
    required this.total,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final progress = widget.totalGoal > 0
        ? (widget.totalCurrent / widget.totalGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring grande
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress * _anim.value,
                  color: Colors.white,
                  trackColor: Colors.white.withOpacity(0.2),
                  strokeWidth: 7,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * _anim.value * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'total',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u20a1${widget.totalCurrent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'de \u20a1${widget.totalGoal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryPill(
                      label: '${widget.completed}/${widget.total}',
                      sublabel: 'completadas',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _SummaryPill({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            '$label $sublabel',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saving Card ──────────────────────────────────────────────────────────────

class _SavingCard extends StatefulWidget {
  final AppThemeColors colors;
  final Saving saving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavingCard({
    required this.colors,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SavingCard> createState() => _SavingCardState();
}

class _SavingCardState extends State<_SavingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final s = widget.saving;
    final progress = s.goalAmount > 0
        ? (s.currentAmount / s.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (s.goalAmount - s.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final daysLeft = s.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final isCompleted = s.isCompleted || progress >= 1.0;

    Color accentColor;
    if (isCompleted) {
      accentColor = colors.success;
    } else if (isOverdue) {
      accentColor = colors.error;
    } else if (daysLeft < 30) {
      accentColor = colors.warning;
    } else {
      accentColor = colors.primary;
    }

    return GestureDetector(
      onLongPress: widget.onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? colors.success.withOpacity(0.4)
                : colors.border,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Ring de progreso
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) => SizedBox(
                          width: 52,
                          height: 52,
                          child: CustomPaint(
                            painter: _RingPainter(
                              progress: progress * _anim.value,
                              color: accentColor,
                              trackColor: accentColor.withOpacity(0.1),
                              strokeWidth: 4.5,
                            ),
                            child: Center(
                              child: Text(
                                '${(progress * _anim.value * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '✓ Completada',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: colors.success,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted
                                  ? '¡Meta alcanzada! 🎉'
                                  : isOverdue
                                  ? 'Venció hace ${daysLeft.abs()} días'
                                  : daysLeft == 0
                                  ? 'Vence hoy'
                                  : 'Faltan $daysLeft días',
                              style: TextStyle(
                                fontSize: 12,
                                color: isCompleted
                                    ? colors.success
                                    : isOverdue
                                    ? colors.error
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.iconDefault,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          color: accentColor.withOpacity(0.1),
                        ),
                        AnimatedBuilder(
                          animation: _anim,
                          builder: (_, __) => FractionallySizedBox(
                            widthFactor: progress * _anim.value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Montos
                  Row(
                    children: [
                      Expanded(
                        child: _MontoStat(
                          label: 'Ahorrado',
                          value: '\u20a1${s.currentAmount.toStringAsFixed(0)}',
                          color: accentColor,
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _MontoStat(
                          label: 'Meta',
                          value: '\u20a1${s.goalAmount.toStringAsFixed(0)}',
                          color: colors.textPrimary,
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _MontoStat(
                          label: 'Faltante',
                          value: '\u20a1${remaining.toStringAsFixed(0)}',
                          color: colors.textSecondary,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MontoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppThemeColors colors;

  const _MontoStat({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _SavingSheet extends StatefulWidget {
  final AppThemeColors colors;
  final Saving? saving;

  const _SavingSheet({required this.colors, this.saving});

  @override
  State<_SavingSheet> createState() => _SavingSheetState();
}

class _SavingSheetState extends State<_SavingSheet> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isCompleted = false;

  bool get _isEdit => widget.saving != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.saving!;
      _nameCtrl.text = s.name;
      _goalCtrl.text = s.goalAmount.toStringAsFixed(0);
      _currentCtrl.text = s.currentAmount.toStringAsFixed(0);
      _dueDate = s.dueDate;
      _isCompleted = s.isCompleted;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final goal = double.tryParse(_goalCtrl.text.replaceAll(',', '.')) ?? 0;
    final current =
        double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;

    if (name.isEmpty || goal <= 0) return;

    final saving = Saving(
      id: _isEdit ? widget.saving!.id : '',
      name: name,
      goalAmount: goal,
      currentAmount: current,
      dueDate: _dueDate,
      isCompleted: _isCompleted || current >= goal,
    );

    if (_isEdit) {
      context.read<SavingBloc>().add(UpdateSaving(saving: saving));
    } else {
      context.read<SavingBloc>().add(AddSaving(saving: saving));
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final colors = widget.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
    final colors = widget.colors;

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
          // Handle + título
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
                      _isEdit ? 'Editar meta' : 'Nueva meta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_isEdit)
                      GestureDetector(
                        onTap: () {
                          context.read<SavingBloc>().add(
                            DeleteSaving(id: widget.saving!.id),
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Eliminar',
                          style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Contenido
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
                  // Nombre
                  _Label(text: 'NOMBRE DE LA META', colors: colors),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _nameCtrl,
                    hint: 'Ej: Vacaciones, Auto nuevo...',
                    colors: colors,
                  ),
                  const SizedBox(height: 20),

                  // Montos en fila
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'MONTO META', colors: colors),
                            const SizedBox(height: 8),
                            _Field(
                              controller: _goalCtrl,
                              hint: '0',
                              prefix: '₡',
                              keyboardType: TextInputType.number,
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'YA AHORRADO', colors: colors),
                            const SizedBox(height: 8),
                            _Field(
                              controller: _currentCtrl,
                              hint: '0',
                              prefix: '₡',
                              keyboardType: TextInputType.number,
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fecha límite
                  _Label(text: 'FECHA LÍMITE', colors: colors),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
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
                            '${_dueDate.day} ${_months[_dueDate.month]} ${_dueDate.year}',
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

                  if (_isEdit) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => setState(() => _isCompleted = !_isCompleted),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? colors.success.withOpacity(0.1)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isCompleted
                                ? colors.success.withOpacity(0.4)
                                : colors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: _isCompleted
                                  ? colors.success
                                  : colors.iconDefault,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Marcar como completada',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isCompleted
                                    ? colors.success
                                    : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEdit ? 'Guardar cambios' : 'Crear meta',
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAdd;

  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐷', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Sin metas de ahorro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera meta y empieza a ahorrar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Nueva meta',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

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
            'Error al cargar metas',
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _Label({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textSecondary,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final AppThemeColors colors;

  const _Field({
    required this.controller,
    required this.hint,
    required this.colors,
    this.prefix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
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
    required this.strokeWidth,
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
