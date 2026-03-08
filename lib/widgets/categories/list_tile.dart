import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/widgets/categories/add.dart';

class CategoryListTile extends StatelessWidget {
  final Categories category;

  const CategoryListTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEdit(context),
        borderRadius: BorderRadius.circular(18),
        splashColor: colors.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    category.icon ?? '📦',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (category.subcategories != null &&
                        category.subcategories!.isNotEmpty)
                      Text(
                        '${category.subcategories!.length} subcategorías',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: colors.iconDefault,
                ),
                onPressed: () => _confirmDelete(context, colors),
                splashRadius: 20,
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.iconDefault),
            ],
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ThemeProvider>(),
          child: AddCategorySheet(categoryToEdit: category),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppThemeColors colors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar categoría?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Se eliminará "${category.name}" y todas sus subcategorías.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (category.id != null) {
                context.read<CategoryBloc>().add(
                  DeleteCategory(id: category.id!),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
