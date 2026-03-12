import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/models/note_priority.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/widgets/notes/card.dart';

/// Lista de notas agrupadas por categoría, con headers colapsables.
/// Cada grupo tiene animación de expand/collapse suave.
class GroupedNotesList extends StatefulWidget {
  final List<Note> notes;
  final AppThemeColors colors;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<Note> onToggleComplete;
  final ValueChanged<Note> onPay;
  final bool startCollapsed; // si true, todos los grupos empiezan cerrados

  const GroupedNotesList({
    super.key,
    required this.notes,
    required this.colors,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    required this.onPay,
    this.startCollapsed = true,
  });

  @override
  State<GroupedNotesList> createState() => _GroupedNotesListState();
}

class _GroupedNotesListState extends State<GroupedNotesList> {
  // Categorías colapsadas
  late final Set<String> _collapsed;

  @override
  void initState() {
    super.initState();
    // Calcular grupos desde ya y colapsar todos si startCollapsed
    _collapsed = {};
    if (widget.startCollapsed) {
      for (final n in widget.notes) {
        final label = n.category.isEmpty ? 'Sin categoría' : n.category;
        _collapsed.add(label);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.emptyIcon, size: 48, color: widget.colors.iconDefault),
            const SizedBox(height: 14),
            Text(
              widget.emptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.emptySubtitle,
              style: TextStyle(
                fontSize: 13,
                color: widget.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar por categoría
    final groups = _groupNotes(widget.notes);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final group = groups[i];
        final label = group.category.isEmpty ? 'Sin categoría' : group.category;
        final isCollapsed = _collapsed.contains(label);

        return _CategoryGroup(
          label: label,
          notes: group.notes,
          colors: widget.colors,
          isCollapsed: isCollapsed,
          onToggle: () => setState(() {
            if (isCollapsed) {
              _collapsed.remove(label);
            } else {
              _collapsed.add(label);
            }
          }),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onToggleComplete: widget.onToggleComplete,
          onPay: widget.onPay,
        );
      },
    );
  }

  List<_NoteGroup> _groupNotes(List<Note> notes) {
    final map = <String, List<Note>>{};
    for (final n in notes) {
      final key = n.category.isEmpty ? '' : n.category;
      map.putIfAbsent(key, () => []).add(n);
    }
    // Orden: categorías con nombre primero (alfabético), luego "Sin categoría"
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1;
        if (b.isEmpty) return -1;
        return a.compareTo(b);
      });
    return keys.map((k) => _NoteGroup(category: k, notes: map[k]!)).toList();
  }
}

class _NoteGroup {
  final String category;
  final List<Note> notes;
  _NoteGroup({required this.category, required this.notes});
}

// ─── Grupo colapsable ─────────────────────────────────────────────────────────

class _CategoryGroup extends StatelessWidget {
  final String label;
  final List<Note> notes;
  final AppThemeColors colors;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<Note> onToggleComplete;
  final ValueChanged<Note> onPay;

  const _CategoryGroup({
    required this.label,
    required this.notes,
    required this.colors,
    required this.isCollapsed,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    required this.onPay,
  });

  // Cuenta cuántas tienen prioridad alta o están vencidas
  int get _urgentCount =>
      notes.where((n) => n.priority == NotePriority.high || n.isOverdue).length;

  @override
  Widget build(BuildContext context) {
    final urgent = _urgentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header del grupo ────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Ícono animado de collapse
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                // Nombre de categoría
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                // Badge de urgentes si los hay
                if (urgent > 0 && !isCollapsed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$urgent urgente${urgent > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Contador total
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notes.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Notas animadas ───────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isCollapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            children: [
              ...notes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteCard(
                    note: n,
                    colors: colors,
                    onTap: () => onTap(n),
                    onLongPress: () => onLongPress(n),
                    onToggleComplete: () => onToggleComplete(n),
                    onPay: () => onPay(n),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),

        // Divider entre grupos
        Divider(
          height: 1,
          thickness: 0.5,
          color: colors.border.withOpacity(0.4),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
