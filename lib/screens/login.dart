import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/auth/auth_bloc.dart';
import 'package:where_ma_money_go/blocs/auth/auth_event.dart';
import 'package:where_ma_money_go/blocs/auth/auth_state.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/screens/signup.dart';
import 'package:where_ma_money_go/widgets/auth/button.dart';
import 'package:where_ma_money_go/widgets/auth/error.dart';
import 'package:where_ma_money_go/widgets/auth/text_field.dart';
import 'package:where_ma_money_go/screens/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainScreen()),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          if (state is AuthEmailUnverified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Tu correo no ha sido verificado. Revisa tu bandeja de entrada.',
                ),
                backgroundColor: colors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          if (state is AuthVerificationEmailSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Correo de verificación enviado. Revisa tu bandeja de entrada.',
                ),
                backgroundColor: colors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Correo de recuperación enviado.'),
                backgroundColor: colors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final error = state is AuthError ? state.message : null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),
                    _AuthLogo(colors: colors),
                    const SizedBox(height: 40),
                    Text(
                      'Bienvenido\nde vuelta',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.1,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (error != null) ...[
                      AuthErrorBanner(message: error),
                      const SizedBox(height: 20),
                    ],
                    AuthTextField(
                      label: 'CORREO',
                      hint: 'tu@correo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      label: 'CONTRASEÑA',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa tu contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showPasswordReset(context, colors),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthButton(
                      label: 'Iniciar sesión',
                      onTap: _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 32),
                    _Divider(colors: colors),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AuthBloc>(),
                                  child: const SignUpScreen(),
                                ),
                              ),
                            ),
                            child: Text(
                              'Regístrate',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPasswordReset(BuildContext context, AppThemeColors colors) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordResetSheet(
        colors: colors,
        controller: controller,
        onSend: (email) {
          context.read<AuthBloc>().add(AuthSendPasswordReset(email: email));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Correo de recuperación enviado'),
              backgroundColor: colors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PasswordResetSheet extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController controller;
  final void Function(String) onSend;

  const _PasswordResetSheet({
    required this.colors,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            'Recuperar contraseña',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'tu@correo.com',
              hintStyle: TextStyle(color: colors.textSecondary),
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
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: colors.iconDefault,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => onSend(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enviar enlace',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  final AppThemeColors colors;
  const _AuthLogo({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppThemeColors colors;
  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}
