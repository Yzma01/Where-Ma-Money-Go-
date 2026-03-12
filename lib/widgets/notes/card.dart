import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/widgets/notes/badge.dart';
import 'pay_button.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final AppThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleComplete;
  final VoidCallback onPay;

  const NoteCard({
    super.key,
    required this.note,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    required this.onPay,
  });

  static const _freqLabel = {
    'daily': 'Diario',
    'weekly': 'Semanal',
    'monthly': 'Mensual',
    'yearly': 'Anual',
  };

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

  String _dueLabel(DateTime due, String frequency) {
    final today = DateTime.now();
    final daysLeft = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (daysLeft <= 0) return 'Vence hoy';
    if (daysLeft == 1) return 'Vence mañana';
    if (daysLeft <= 7) return 'En $daysLeft días';
    return 'Vence ${due.day} ${_months[due.month]}';
  }

  Color _dueColor(DateTime due, AppThemeColors colors) {
    final today = DateTime.now();
    final daysLeft = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (daysLeft <= 1) return colors.error;
    if (daysLeft <= 5) return colors.warning;
    return colors.textSecondary;
  }

  String _relDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = note.isCompleted;
    final isPendingRecurrent = note.isRecurrent && !completed;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: completed ? colors.surface.withOpacity(0.45) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPendingRecurrent
                ? colors.warning.withOpacity(0.4)
                : completed
                ? colors.border.withOpacity(0.4)
                : colors.border,
            width: isPendingRecurrent ? 1.0 : 0.5,
          ),
          boxShadow: completed
              ? []
              : [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggleComplete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, right: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: completed
                              ? colors.success
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: completed ? colors.success : colors.border,
                            width: 1.5,
                          ),
                        ),
                        child: completed
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: completed
                                ? colors.textSecondary
                                : colors.textPrimary,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colors.textSecondary,
                          ),
                        ),
                        if (note.content.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              height: 1.4,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            NoteBadge(
                              icon: Icons.calendar_today_outlined,
                              label: _relDate(note.createdAt),
                              color: colors.textSecondary,
                              bg: colors.border.withOpacity(0.25),
                            ),
                            if (note.isRecurrent &&
                                note.recurrent?.nextDueDate != null) ...[
                              NoteBadge(
                                icon: Icons.event_outlined,
                                label: _dueLabel(
                                  note.recurrent!.nextDueDate!,
                                  note.recurrent!.frequency,
                                ),
                                color: _dueColor(
                                  note.recurrent!.nextDueDate!,
                                  colors,
                                ),
                                bg: _dueColor(
                                  note.recurrent!.nextDueDate!,
                                  colors,
                                ).withOpacity(0.1),
                              ),
                            ],
                            if (note.hasBill && note.bill != null)
                              NoteBadge(
                                icon: Icons.receipt_outlined,
                                label:
                                    '\u20a1${note.bill!.amount.toStringAsFixed(0)}',
                                color: note.bill!.cashFlow == 'expense'
                                    ? colors.error
                                    : colors.success,
                                bg:
                                    (note.bill!.cashFlow == 'expense'
                                            ? colors.error
                                            : colors.success)
                                        .withOpacity(0.1),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isPendingRecurrent && note.hasBill && note.bill != null)
              PayButton(colors: colors, note: note, onPay: onPay),
          ],
        ),
      ),
    );
  }
}
