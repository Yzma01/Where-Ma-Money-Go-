import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class NotesTabBar extends StatelessWidget {
  final TabController controller;
  final AppThemeColors colors;
  final List<int> counts;

  const NotesTabBar({
    super.key,
    required this.controller,
    required this.colors,
    required this.counts,
  });

  static const _labels = ['Recurrentes', 'Notas', 'Completadas'];
  static const _icons = [
    Icons.repeat_rounded,
    Icons.sticky_note_2_outlined,
    Icons.check_circle_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        children: List.generate(3, (i) {
          final sel = controller.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? colors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? colors.primary : colors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _icons[i],
                      size: 16,
                      color: sel ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : colors.textSecondary,
                      ),
                    ),
                    if (counts[i] > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white.withOpacity(0.25)
                              : colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${counts[i]}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: sel ? Colors.white : colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
