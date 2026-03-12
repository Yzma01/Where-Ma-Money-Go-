import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_event.dart';
import 'package:where_ma_money_go/blocs/notes/notes_state.dart';
import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/recurrent.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:where_ma_money_go/widgets/notes/header.dart';
import 'package:where_ma_money_go/widgets/notes/list.dart';
import 'package:where_ma_money_go/widgets/notes/recurrent_tab.dart';
import 'package:where_ma_money_go/widgets/notes/sheet.dart';
import 'package:where_ma_money_go/widgets/notes/tab_bar.dart';

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

  // ── En notes_screen.dart, reemplaza _payNote completo ─────────────────────────

  void _payNote(BuildContext ctx, Note note) {
    if (note.bill == null || note.recurrent == null) return;
    final bill = note.bill!;
    final recurrent = note.recurrent!;
    final now = DateTime.now();

    // 1. Registrar el bill con la fecha de hoy
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
        ),
      ),
    );

    // 2. Calcular la próxima fecha de pago desde hoy
    final nextDue = Recurrent.calcNextDue(now, recurrent.frequency);

    // 3. Actualizar la nota:
    //    - isCompleted: true  (desaparece de "Recurrentes" hasta que sea tiempo)
    //    - recurrent.nextDueDate = nextDue  (para saber cuándo reactivar)
    ctx.read<NotesBloc>().add(
      UpdateNote(
        note: Note(
          id: note.id,
          title: note.title,
          content: note.content,
          createdAt: note.createdAt,
          hasBill: note.hasBill,
          bill: note.bill,
          isRecurrent: note.isRecurrent,
          isCompleted: true,
          recurrent: recurrent.copyWith(nextDueDate: nextDue),
        ),
      ),
    );

    final colors = ctx.read<ThemeProvider>().colors;
    final nextLabel = _formatNextDue(nextDue, recurrent.frequency);

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✅ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Pago registrado · \u20a1${bill.amount.toStringAsFixed(0)}  ·  Próximo $nextLabel',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: colors.success,
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
          hasBill: n.hasBill,
          bill: n.bill,
          isRecurrent: n.isRecurrent,
          isCompleted: !n.isCompleted,
          recurrent: n.recurrent,
        ),
      ),
    );
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

            // ✅ Reactivar notas recurrentes cuya fecha ya llegó
            // Se hace una sola vez por build, solo las que necesitan cambio
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final toReactivate = allNotes.where((n) {
                if (!n.isRecurrent) return false;
                if (!n.isCompleted) return false; // ya está pendiente, skip
                return n.recurrent?.isDue ?? false; // llegó su fecha
              }).toList();

              for (final note in toReactivate) {
                context.read<NotesBloc>().add(
                  UpdateNote(
                    note: Note(
                      id: note.id,
                      title: note.title,
                      content: note.content,
                      createdAt: note.createdAt,
                      hasBill: note.hasBill,
                      bill: note.bill,
                      isRecurrent: note.isRecurrent,
                      isCompleted: false, // ← vuelve a pendiente
                      recurrent:
                          note.recurrent, // nextDueDate se mantiene intacto
                    ),
                  ),
                );
              }
            });

            final recurrentPending = allNotes
                .where((n) => n.isRecurrent && !n.isCompleted)
                .toList();

            final recurrentPaid = allNotes
                .where((n) => n.isRecurrent && n.isCompleted)
                .toList();

            final completed = allNotes
                .where((n) => n.isCompleted && !n.isRecurrent)
                .toList();

            final regular = allNotes
                .where((n) => !n.isRecurrent && !n.isCompleted)
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
                      recurrentPending.length +
                          recurrentPaid.length, // total recurrentes
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
                            NotesList(
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
                            NotesList(
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
        onPressed: () => _openNote(context, colors),
        backgroundColor: colors.primary,
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
