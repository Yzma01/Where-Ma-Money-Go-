import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SheetSegmentedRow extends StatelessWidget {
  final AppThemeColors colors;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const SheetSegmentedRow({
    super.key,
    required this.colors,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((o) {
          final sel = selected == o.$1;
          final accent = o.$1 == 'expense' ? colors.error : colors.success;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
