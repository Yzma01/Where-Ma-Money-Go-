import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class NotesHeader extends StatelessWidget {
  final AppThemeColors colors;
  final bool searching;
  final TextEditingController searchCtrl;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;

  const NotesHeader({
    super.key,
    required this.colors,
    required this.searching,
    required this.searchCtrl,
    required this.onToggleSearch,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 12),
      child: Row(
        children: [
          if (!searching) ...[
            Text(
              'Notas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
          ] else
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, width: 0.5),
                ),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  onChanged: onSearchChanged,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar notas...',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.iconDefault,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onToggleSearch,
            icon: Icon(
              searching ? Icons.close_rounded : Icons.search_rounded,
              color: colors.textPrimary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
