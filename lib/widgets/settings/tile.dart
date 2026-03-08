import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final iconColor = isDestructive ? colors.error : colors.primary;
    final iconBg = isDestructive
        ? colors.error.withOpacity(0.1)
        : colors.primary.withOpacity(0.12);
    final labelColor = isDestructive ? colors.error : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: colors.primary.withOpacity(0.08),
        highlightColor: colors.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (value != null && trailing == null) ...[
                Text(
                  value!,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(width: 6),
              ],
              if (onTap != null && trailing == null)
                Icon(Icons.chevron_right, size: 18, color: colors.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}
