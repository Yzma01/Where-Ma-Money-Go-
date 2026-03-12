import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final AppThemeColors colors;
  final String hint;
  final int maxLines;
  final double fontSize;
  final bool bold;
  final TextInputType? keyboardType;
  final String? prefix;
  final Color? accentColor;

  const SheetField({
    super.key,
    required this.ctrl,
    required this.colors,
    required this.hint,
    required this.maxLines,
    required this.fontSize,
    required this.bold,
    this.keyboardType,
    this.prefix,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? colors.primary;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: accentColor ?? colors.textPrimary,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        prefixText: prefix,
        prefixStyle: TextStyle(
          color: accent.withOpacity(0.6),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
