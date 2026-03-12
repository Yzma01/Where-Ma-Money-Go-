import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/note_priority.dart';
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

  String _relDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${d.day} ${_months[d.month]}';
  }

  String _dueDateLabel(DateTime d) {
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final dueD = DateTime(d.year, d.month, d.day);
    final diff = dueD.difference(todayD).inDays;
    if (diff < 0) return 'Venció hace ${diff.abs()} días';
    if (diff == 0) return 'Vence hoy';
    if (diff == 1) return 'Vence mañana';
    if (diff <= 7) return 'Vence en $diff días';
    return 'Vence ${d.day} ${_months[d.month]}';
  }

  Color _priorityColor(AppThemeColors c) {
    switch (note.priority) {
      case NotePriority.high:
        return c.error;
      case NotePriority.medium:
        return c.warning;
      case NotePriority.low:
        return c.success;
      case NotePriority.none:
        return c.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = note.isCompleted;
    final isPendingRecurrent = note.isRecurrent && !completed;
    final hasPriority = note.priority != NotePriority.none;
    final priorityColor = _priorityColor(colors);

    // Border color logic: prioridad alta > recurrente > overdue > normal
    Color borderColor;
    double borderWidth;
    if (!completed && note.isOverdue) {
      borderColor = colors.error.withOpacity(0.6);
      borderWidth = 1.0;
    } else if (isPendingRecurrent) {
      borderColor = colors.warning.withOpacity(0.4);
      borderWidth = 1.0;
    } else if (!completed && note.priority == NotePriority.high) {
      borderColor = colors.error.withOpacity(0.35);
      borderWidth = 1.0;
    } else if (completed) {
      borderColor = colors.border.withOpacity(0.4);
      borderWidth = 0.5;
    } else {
      borderColor = colors.border;
      borderWidth = 0.5;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: completed ? colors.surface.withOpacity(0.45) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
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
                  // Indicador de prioridad (línea izquierda) si no es none
                  if (hasPriority && !completed)
                    Container(
                      width: 3,
                      height: 48,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
                            // Emoji de prioridad en esquina
                            if (hasPriority && !completed)
                              Text(
                                note.priority.emoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                          ],
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
                            // Fecha de creación
                            NoteBadge(
                              icon: Icons.calendar_today_outlined,
                              label: _relDate(note.createdAt),
                              color: colors.textSecondary,
                              bg: colors.border.withOpacity(0.25),
                            ),
                            // Categoría de nota
                            if (note.category.isNotEmpty)
                              NoteBadge(
                                icon: Icons.label_outline_rounded,
                                label: note.category,
                                color: colors.primary,
                                bg: colors.primary.withOpacity(0.1),
                              ),
                            // Prioridad badge (solo si no es none)
                            if (hasPriority && !completed)
                              NoteBadge(
                                icon: Icons.flag_outlined,
                                label: note.priority.label,
                                color: priorityColor,
                                bg: priorityColor.withOpacity(0.1),
                              ),
                            // Fecha de caducidad
                            if (note.hasDueDate &&
                                note.dueDate != null &&
                                !completed)
                              NoteBadge(
                                icon: note.isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.access_time_rounded,
                                label: _dueDateLabel(note.dueDate!),
                                color: note.isOverdue
                                    ? colors.error
                                    : note.isDueSoon
                                    ? colors.warning
                                    : colors.textSecondary,
                                bg:
                                    (note.isOverdue
                                            ? colors.error
                                            : note.isDueSoon
                                            ? colors.warning
                                            : colors.textSecondary)
                                        .withOpacity(0.1),
                              ),
                            // Recurrente
                            if (note.isRecurrent && note.recurrent != null)
                              NoteBadge(
                                icon: Icons.repeat_rounded,
                                label:
                                    _freqLabel[note.recurrent!.frequency] ??
                                    note.recurrent!.frequency,
                                color: colors.primaryLight,
                                bg: colors.primaryLight.withOpacity(0.1),
                              ),
                            // Monto del bill
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
