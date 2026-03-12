import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/notes/notes_state.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/services/notifications/notes/service.dart';
import 'package:where_ma_money_go/widgets/notes/group_list.dart';
import 'package:where_ma_money_go/widgets/notes/header.dart';
import 'package:where_ma_money_go/widgets/notes/recurrent_tab.dart';
import 'package:where_ma_money_go/widgets/notes/sheet.dart';
import 'package:where_ma_money_go/widgets/notes/tab_bar.dart';
import 'package:where_ma_money_go/models/note_priority.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    context.read<NotesBloc>().add(LoadNotes());
    // Inicializar notificaciones y pedir permisos
    NotificationService.instance.init().then((_) {
      NotificationService.instance.requestPermissions();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchCtrl.clear();
        context.read<NotesBloc>().add(LoadNotes());
      }
    });
  }

  void _openNote(BuildContext ctx, AppThemeColors colors, {Note? note}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ctx.read<NotesBloc>()),
          BlocProvider.value(value: ctx.read<BillsBloc>()),
          BlocProvider.value(value: ctx.read<CategoryBloc>()),
          BlocProvider.value(value: ctx.read<SavingBloc>()),
        ],
        child: NoteSheet(colors: colors, note: note),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext ctx,
    AppThemeColors colors,
    Note note,
  ) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar nota',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '¿Eliminar "${note.title}"?',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (ok == true && ctx.mounted) {
      ctx.read<NotesBloc>().add(DeleteNote(id: note.id));
    }
  }

  void _payNote(BuildContext ctx, Note note) {
    if (note.bill == null || note.recurrent == null) return;
    final bill = note.bill!;
    final recurrent = note.recurrent!;
    final now = DateTime.now();

    // 1. Registrar el gasto en el historial de bills
    ctx.read<BillsBloc>().add(
      AddBill(
        bill: Bill(
          id: const Uuid().v4(),
          category: bill.category,
          subcategory: bill.subcategory,
          amount: bill.amount,
          date: now,
          month: now.month.toString(),
          type: 'fixed',
          cashFlow: bill.cashFlow,
          savingId: bill.savingId,
        ),
      ),
    );

    // 2. Si tiene saving asociado, sumar (income) o restar (expense)
    if (bill.savingId != null && bill.savingId!.isNotEmpty) {
      final savingState = ctx.read<SavingBloc>().state;
      if (savingState is SavingLoaded) {
        try {
          final saving = savingState.savings.firstWhere(
            (s) => s.id == bill.savingId,
          );
          final delta = bill.cashFlow == 'expense' ? -bill.amount : bill.amount;
          final newAmount = (saving.currentAmount + delta).clamp(
            0.0,
            double.infinity,
          );
          ctx.read<SavingBloc>().add(
            UpdateSaving(
              saving: saving.copyWith(
                currentAmount: newAmount,
                isCompleted: newAmount >= saving.goalAmount,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Saving update error: $e');
        }
      }
    }

    // 3. Marcar nota como pagada y calcular próximo vencimiento
    final nextDue = Recurrent.calcNextDue(now, recurrent.frequency);
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      dueDate: note.dueDate,
      category: note.category,
      hasDueDate: note.hasDueDate,
      hasBill: note.hasBill,
      priority: note.priority,
      bill: note.bill,
      isRecurrent: note.isRecurrent,
      isCompleted: true,
      recurrent: recurrent.copyWith(nextDueDate: nextDue),
    );
    ctx.read<NotesBloc>().add(UpdateNote(note: updatedNote));

    // Reprogramar notificación para el próximo ciclo
    NotificationService.instance.scheduleForNote(updatedNote);

    final colors = ctx.read<ThemeProvider>().colors;
    final nextLabel = _formatNextDue(nextDue, recurrent.frequency);
    final isSaving = bill.savingId != null && bill.savingId!.isNotEmpty;
    final isExpense = bill.cashFlow == 'expense';

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(
              isSaving ? (isExpense ? '📤 ' : '🐖 ') : '✅ ',
              style: const TextStyle(fontSize: 16),
            ),
            Expanded(
              child: Text(
                isSaving
                    ? '${isExpense ? 'Retiro' : 'Aporte'} registrado · \u20a1${bill.amount.toStringAsFixed(0)}  ·  Próximo $nextLabel'
                    : 'Pago registrado · \u20a1${bill.amount.toStringAsFixed(0)}  ·  Próximo $nextLabel',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isSaving
            ? (isExpense ? colors.warning : colors.primary)
            : colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatNextDue(DateTime date, String frequency) {
    const months = [
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
    if (frequency == 'daily') return 'mañana';
    return '${date.day} ${months[date.month]}';
  }

  void _toggleComplete(BuildContext ctx, Note n) {
    ctx.read<NotesBloc>().add(
      UpdateNote(
        note: Note(
          id: n.id,
          title: n.title,
          content: n.content,
          createdAt: n.createdAt,
          dueDate: n.dueDate,
          category: n.category,
          hasDueDate: n.hasDueDate,
          hasBill: n.hasBill,
          priority: n.priority,
          bill: n.bill,
          isRecurrent: n.isRecurrent,
          isCompleted: !n.isCompleted,
          recurrent: n.recurrent,
        ),
      ),
    );
  }

  /// Ordena por prioridad desc, luego por dueDate asc
  List<Note> _sortNotes(List<Note> notes) {
    final sorted = List<Note>.from(notes);
    sorted.sort((a, b) {
      // Prioridad alta primero
      final pCmp = b.priority.value.compareTo(a.priority.value);
      if (pCmp != 0) return pCmp;
      // Overdue primero
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // DueDate más pronto primero
      if (a.hasDueDate &&
          b.hasDueDate &&
          a.dueDate != null &&
          b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.hasDueDate) return -1;
      if (b.hasDueDate) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            final allNotes = state is NotesLoaded ? state.notes : <Note>[];

            // Reactivar notas recurrentes cuya fecha llegó
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // Sincronizar notificaciones con el estado actual
              if (state is NotesLoaded) {
                NotificationService.instance.syncAll(allNotes);
              }

              final toReactivate = allNotes.where((n) {
                if (!n.isRecurrent || !n.isCompleted) return false;
                return n.recurrent?.isDue ?? false;
              }).toList();
              for (final note in toReactivate) {
                // Notificación inmediata: "volvió a pendiente"
                NotificationService.instance.notifyReactivated(note);

                context.read<NotesBloc>().add(
                  UpdateNote(
                    note: Note(
                      id: note.id,
                      title: note.title,
                      content: note.content,
                      createdAt: note.createdAt,
                      dueDate: note.dueDate,
                      category: note.category,
                      hasDueDate: note.hasDueDate,
                      hasBill: note.hasBill,
                      priority: note.priority,
                      bill: note.bill,
                      isRecurrent: note.isRecurrent,
                      isCompleted: false,
                      recurrent: note.recurrent,
                    ),
                  ),
                );
              }
            });

            // Separar por tipo
            final recurrentPending = allNotes
                .where((n) => n.isRecurrent && !n.isCompleted)
                .toList();
            final recurrentPaid = allNotes
                .where((n) => n.isRecurrent && n.isCompleted)
                .toList();
            final regular = _sortNotes(
              allNotes.where((n) => !n.isRecurrent && !n.isCompleted).toList(),
            );
            final completed = allNotes
                .where((n) => n.isCompleted && !n.isRecurrent)
                .toList();

            return Column(
              children: [
                NotesHeader(
                  colors: colors,
                  searching: _searching,
                  searchCtrl: _searchCtrl,
                  onToggleSearch: _toggleSearch,
                  onSearchChanged: (q) {
                    if (q.trim().isEmpty) {
                      context.read<NotesBloc>().add(LoadNotes());
                    } else {
                      context.read<NotesBloc>().add(
                        SearchNotes(query: q.trim()),
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: NotesTabBar(
                    controller: _tabs,
                    colors: colors,
                    counts: [
                      recurrentPending.length + recurrentPaid.length,
                      regular.length,
                      completed.length,
                    ],
                  ),
                ),
                Expanded(
                  child: state is NotesLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.primary,
                          ),
                        )
                      : state is NotesError
                      ? _ErrorView(
                          colors: colors,
                          message: state.message,
                          onRetry: () =>
                              context.read<NotesBloc>().add(LoadNotes()),
                        )
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            RecurrentTab(
                              pending: recurrentPending,
                              paid: recurrentPaid,
                              colors: colors,
                              onTap: (n) => _openNote(context, colors, note: n),
                              onLongPress: (n) =>
                                  _confirmDelete(context, colors, n),
                              onToggleComplete: (n) =>
                                  _toggleComplete(context, n),
                              onPay: (n) =>
                                  n.hasBill ? _payNote(context, n) : null,
                            ),
                            // Notas agrupadas por categoría con collapse
                            GroupedNotesList(
                              notes: regular,
                              colors: colors,
                              emptyIcon: Icons.sticky_note_2_outlined,
                              emptyTitle: 'Sin notas',
                              emptySubtitle: 'Crea tu primera nota',
                              onTap: (n) => _openNote(context, colors, note: n),
                              onLongPress: (n) =>
                                  _confirmDelete(context, colors, n),
                              onToggleComplete: (n) =>
                                  _toggleComplete(context, n),
                              onPay: (_) => null,
                            ),
                            GroupedNotesList(
                              notes: completed,
                              colors: colors,
                              emptyIcon: Icons.check_circle_outline_rounded,
                              emptyTitle: 'Sin completadas',
                              emptySubtitle:
                                  'Las notas marcadas aparecerán aquí',
                              onTap: (n) => _openNote(context, colors, note: n),
                              onLongPress: (n) =>
                                  _confirmDelete(context, colors, n),
                              onToggleComplete: (n) =>
                                  _toggleComplete(context, n),
                              onPay: (_) => null,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'notes_fab',
        onPressed: () =>
            _openNote(context, context.read<ThemeProvider>().colors),
        backgroundColor: context.watch<ThemeProvider>().colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nueva',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final AppThemeColors colors;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

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
      ),
    );
  }
}
