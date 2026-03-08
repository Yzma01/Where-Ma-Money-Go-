import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/auth/auth_bloc.dart';
import 'package:where_ma_money_go/blocs/auth/auth_event.dart';
import 'package:where_ma_money_go/blocs/auth/auth_state.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  Timer? _checkTimer;
  Timer? _resendCooldown;
  int _cooldownSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Verificar automáticamente cada 5 segundos
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<AuthBloc>().add(AuthCheckEmailVerified());
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _resendCooldown?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _resend() {
    if (_cooldownSeconds > 0) return;
    context.read<AuthBloc>().add(AuthSendVerificationEmail());
    setState(() => _cooldownSeconds = 60);
    _resendCooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Botón de cerrar sesión
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthLogoutRequested()),
                      child: Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Ícono animado
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 32,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Verifica tu correo',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Email destacado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.email,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Te enviamos un enlace de verificación.\nRevisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Indicador de revisión automática
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      else
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isLoading
                            ? 'Verificando...'
                            : 'Revisando automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Botón verificar manualmente
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                              AuthCheckEmailVerified(),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ya verifiqué mi correo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón reenviar con cooldown
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _cooldownSeconds > 0 ? null : _resend,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(
                          color: _cooldownSeconds > 0
                              ? colors.border
                              : colors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _cooldownSeconds > 0
                            ? 'Reenviar en ${_cooldownSeconds}s'
                            : 'Reenviar correo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _cooldownSeconds > 0
                              ? colors.textSecondary
                              : colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
