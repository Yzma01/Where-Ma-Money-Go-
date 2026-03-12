import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/widgets/notes/card.dart';

class NotesList extends StatelessWidget {
  final List<Note> notes;
  final AppThemeColors colors;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<Note> onToggleComplete;
  final ValueChanged<Note> onPay;

  const NotesList({
    super.key,
    required this.notes,
    required this.colors,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 52, color: colors.iconDefault),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => NoteCard(
        note: notes[i],
        colors: colors,
        onTap: () => onTap(notes[i]),
        onLongPress: () => onLongPress(notes[i]),
        onToggleComplete: () => onToggleComplete(notes[i]),
        onPay: () => onPay(notes[i]),
      ),
    );
  }
}
