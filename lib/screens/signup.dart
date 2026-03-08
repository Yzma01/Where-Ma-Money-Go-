import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/auth/auth_bloc.dart';
import 'package:where_ma_money_go/blocs/auth/auth_event.dart';
import 'package:where_ma_money_go/blocs/auth/auth_state.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/widgets/auth/button.dart';
import 'package:where_ma_money_go/widgets/auth/error.dart';
import 'package:where_ma_money_go/widgets/auth/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          name: _nameController.text.trim(),
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
      body: BlocBuilder<AuthBloc, AuthState>(
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
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.textPrimary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Crear\ncuenta',
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
                      'Empieza a controlar tu dinero hoy',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (error != null) ...[
                      AuthErrorBanner(message: error),
                      const SizedBox(height: 20),
                    ],
                    AuthTextField(
                      label: 'NOMBRE',
                      hint: 'Tu nombre',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                      hint: 'Mínimo 6 caracteres',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      label: 'CONFIRMAR CONTRASEÑA',
                      hint: 'Repite tu contraseña',
                      controller: _confirmController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    AuthButton(
                      label: 'Crear cuenta',
                      onTap: _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Inicia sesión',
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
}
