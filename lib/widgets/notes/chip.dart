import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SheetChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isEmoji;
  final bool selected;
  final AppThemeColors colors;

  const SheetChip({
    super.key,
    required this.label,
    required this.icon,
    this.isEmoji = true,
    required this.selected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? colors.primary : colors.border,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmoji)
            Text(icon, style: const TextStyle(fontSize: 13))
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? Colors.white : colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
