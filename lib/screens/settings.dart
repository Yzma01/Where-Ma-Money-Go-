import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/screens/saving_plan.dart';
import 'package:where_ma_money_go/widgets/categories/section.dart';
import 'package:where_ma_money_go/widgets/settings/header.dart';
import 'package:where_ma_money_go/widgets/settings/section.dart';
import 'package:where_ma_money_go/widgets/settings/tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openNotSupported(BuildContext context) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Funcionalidad no implementada aún',
          style: TextStyle(color: colors.textPrimary),
        ),
        backgroundColor: colors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SettingsHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SettingsSection(
                      title: 'General',
                      children: [
                        SettingsTile(
                          icon: Icons.category,
                          label: 'Editar Categorías',
                          onTap: () {
                            context.read<CategoryBloc>().add(LoadCategories());
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CategoriesSection(),
                              ),
                            );
                          },
                        ),

                        SettingsTile(
                          icon: Icons.monetization_on,
                          label: 'Plan de Ahorro',
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      SavingPlan(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SettingsSection(
                      title: 'Apariencia',
                      children: [
                        _ThemeToggleTile(),
                        SettingsTile(
                          icon: Icons.language_outlined,
                          label: 'Idioma',
                          value: 'Español',
                          onTap: () => _openNotSupported(context),
                        ),
                        SettingsTile(
                          icon: Icons.attach_money_outlined,
                          label: 'Moneda',
                          value: 'CRC',
                          onTap: () => _openNotSupported(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SettingsSection(
                      title: 'Datos',
                      children: [
                        SettingsTile(
                          icon: Icons.download_outlined,
                          label: 'Exportar datos',
                          onTap: () => _openNotSupported(context),
                        ),
                        SettingsTile(
                          icon: Icons.backup_outlined,
                          label: 'Respaldo en la nube',
                          onTap: () => _openNotSupported(context),
                        ),
                        SettingsTile(
                          icon: Icons.delete_outline,
                          label: 'Borrar todos los datos',
                          isDestructive: true,
                          onTap: () => _confirmDelete(context, colors),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SettingsSection(
                      title: 'Acerca de',
                      children: [
                        SettingsTile(
                          icon: Icons.info_outline,
                          label: 'Versión',
                          value: '1.0.0',
                        ),
                        SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Política de privacidad',
                          onTap: () => _openNotSupported(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
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
          '¿Borrar datos?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Esta acción es irreversible. Se eliminarán todos tus registros.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: colors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final colors = provider.colors;

    return SettingsTile(
      icon: Icons.dark_mode_outlined,
      label: 'Tema oscuro',
      trailing: Switch(
        value: provider.isDarkMode,
        onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
        activeColor: colors.primary,
        inactiveThumbColor: colors.iconDefault,
        inactiveTrackColor: colors.border,
      ),
    );
  }
}
