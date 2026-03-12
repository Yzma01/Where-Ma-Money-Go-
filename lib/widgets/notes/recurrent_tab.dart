import 'package:flutter/material.dart';
import 'package:where_ma_money_go/models/note.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/widgets/notes/group_list.dart';

class RecurrentTab extends StatefulWidget {
  final List<Note> pending;
  final List<Note> paid;
  final AppThemeColors colors;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<Note> onToggleComplete;
  final ValueChanged<Note> onPay;

  const RecurrentTab({
    super.key,
    required this.pending,
    required this.paid,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    required this.onPay,
  });

  @override
  State<RecurrentTab> createState() => _RecurrentTabState();
}

class _RecurrentTabState extends State<RecurrentTab> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isEmpty = widget.pending.isEmpty && widget.paid.isEmpty;

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 52, color: c.iconDefault),
            const SizedBox(height: 16),
            Text(
              'Sin pagos recurrentes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega un pago fijo para recordarlo',
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Sub-tabs ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border, width: 0.5),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _SubTab(
                  label: 'Pendientes',
                  count: widget.pending.length,
                  selected: _sub == 0,
                  selectedColor: c.warning,
                  colors: c,
                  onTap: () => setState(() => _sub = 0),
                ),
                const SizedBox(width: 4),
                _SubTab(
                  label: 'Pagados',
                  count: widget.paid.length,
                  selected: _sub == 1,
                  selectedColor: c.success,
                  colors: c,
                  onTap: () => setState(() => _sub = 1),
                ),
              ],
            ),
          ),
        ),

        // ── Lista agrupada por categoría ──────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _sub == 0
                ? GroupedNotesList(
                    key: const ValueKey('recurrent_pending'),
                    notes: widget.pending,
                    colors: c,
                    startCollapsed: true,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyTitle: '¡Todo al día!',
                    emptySubtitle: 'No hay pagos pendientes',
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    onToggleComplete: widget.onToggleComplete,
                    onPay: widget.onPay,
                  )
                : GroupedNotesList(
                    key: const ValueKey('recurrent_paid'),
                    notes: widget.paid,
                    colors: c,
                    startCollapsed: true,
                    emptyIcon: Icons.receipt_long_outlined,
                    emptyTitle: 'Sin pagos registrados',
                    emptySubtitle: 'Los pagos realizados aparecerán aquí',
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    onToggleComplete: widget.onToggleComplete,
                    onPay: widget.onPay,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SubTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _SubTab({
    required this.label,
    required this.count,
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
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.25)
                        : selectedColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : selectedColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
