import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

/// Selector de categoría de notas con el mismo estilo visual que NotesTabBar.
/// "Todas" siempre aparece primero. Las demás vienen de las categorías reales.
class CategoryTabs extends StatelessWidget {
  final List<String> categories; // sin "Todas", se agrega aquí
  final Map<String, int> counts; // categoria → cantidad de notas
  final String? selected; // null = Todas
  final AppThemeColors colors;
  final ValueChanged<String?> onSelect; // null = Todas

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.counts,
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final all = [null, ...categories.map<String?>((c) => c)];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = all[i]; // null = Todas
          final sel = selected == cat;
          final count = cat == null
              ? counts.values.fold(0, (a, b) => a + b)
              : (counts[cat] ?? 0);
          final label = cat ?? 'Todas';

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? colors.primary : colors.border,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withOpacity(0.25)
                            : colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
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
          );
        },
      ),
    );
  }
}
