import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/providers/user/user_provider.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final name = context.watch<UserProvider>().user?.name ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personaliza tu experiencia $name',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
