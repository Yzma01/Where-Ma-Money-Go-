import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/models/category.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class AddCategorySheet extends StatefulWidget {
  final Categories? categoryToEdit;

  const AddCategorySheet({super.key, this.categoryToEdit});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _subcategoryController;
  String _selectedIcon = '📦';
  final List<String> _subcategories = [];

  bool get _isEditing => widget.categoryToEdit != null;

  static const _icons = [
    '🍔',
    '🚗',
    '🏠',
    '👕',
    '💊',
    '🎬',
    '✈️',
    '📚',
    '💪',
    '🎮',
    '🐾',
    '🎁',
    '💡',
    '🧴',
    '☕',
    '📦',
    '🛒',
    '💰',
    '📱',
    '🏦',
    '🎓',
    '🌱',
    '🎵',
    '🖥️',
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.categoryToEdit;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _subcategoryController = TextEditingController();
    _selectedIcon = cat?.icon ?? '📦';
    if (cat?.subcategories != null) {
      _subcategories.addAll(cat!.subcategories!.map((s) => s.name));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      // Limitar altura máxima al 90% de la pantalla
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + título: fijos, no scrollean
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isEditing ? 'Editar categoría' : 'Nueva categoría',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Contenido scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(text: 'Nombre', colors: colors),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: false,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej. Alimentación',
                      hintStyle: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colors.border,
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel(text: 'Ícono', colors: colors),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(10),
                    // GridView con shrinkWrap para que tome el alto que necesita
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: _icons.length,
                      itemBuilder: (_, i) {
                        final icon = _icons[i];
                        final isSelected = icon == _selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = icon),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary
                                  : colors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel(text: 'Subcategorías', colors: colors),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subcategoryController,
                          onSubmitted: (_) => _addSubcategory(),
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ej. Restaurantes',
                            hintStyle: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colors.border,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addSubcategory,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_subcategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_subcategories.length, (i) {
                        return _SubcategoryChip(
                          label: _subcategories[i],
                          colors: colors,
                          onRemove: () =>
                              setState(() => _subcategories.removeAt(i)),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEditing ? 'Guardar cambios' : 'Crear categoría',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSubcategory() {
    final text = _subcategoryController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subcategories.add(text);
        _subcategoryController.clear();
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final subcategories = _subcategories
        .map((s) => Subcategory(name: s))
        .toList();
    final category = Categories(
      id: widget.categoryToEdit?.id,
      name: name,
      icon: _selectedIcon,
      subcategories: subcategories,
    );

    if (_isEditing) {
      context.read<CategoryBloc>().add(UpdateCategory(category: category));
    } else {
      context.read<CategoryBloc>().add(AddCategory(category: category));
    }

    Navigator.pop(context);
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _FieldLabel({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textSecondary,
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  final VoidCallback onRemove;

  const _SubcategoryChip({
    required this.label,
    required this.colors,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: colors.primary),
          ),
        ],
      ),
    );
  }
}
