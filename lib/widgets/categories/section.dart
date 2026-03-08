import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/widgets/categories/add.dart';
import 'package:where_ma_money_go/widgets/categories/list_tile.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddCategory(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Row(children: [const Spacer()]),
                  ),
                  if (state is CategoryLoading)
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border, width: 0.5),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    )
                  else if (state is CategoryError)
                    _ErrorCard(message: state.message)
                  else if (state is CategoryLoaded && state.categories.isEmpty)
                    _EmptyCard(onAdd: () => _openAddCategory(context))
                  else if (state is CategoryLoaded)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.border, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < state.categories.length;
                              i++
                            ) ...[
                              CategoryListTile(category: state.categories[i]),
                              if (i < state.categories.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 52,
                                  endIndent: 16,
                                  color: colors.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAddCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ThemeProvider>(),
          child: const AddCategorySheet(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.error.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.category_outlined,
                size: 26,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sin categorías',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera categoría',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Agregar categoría',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
