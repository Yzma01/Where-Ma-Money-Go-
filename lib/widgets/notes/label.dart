import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SheetLabel extends StatelessWidget {
  final String text;
  final AppThemeColors colors;

  const SheetLabel(this.text, this.colors, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: colors.textSecondary,
      ),
    );
  }
}
