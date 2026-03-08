import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/providers/user/user_provider.dart';
import 'package:where_ma_money_go/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final UserProvider userProvider;

  AuthBloc({required this.authRepository, required this.userProvider})
    : super(AuthInitial()) {
    on<AuthCheckCurrentUser>(_onCheckCurrentUser);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSendVerificationEmail>(_onSendVerificationEmail);
    on<AuthCheckEmailVerified>(_onCheckEmailVerified);
    on<AuthSendPasswordReset>(_onSendPasswordReset);
  }

  Future<void> _onCheckCurrentUser(
    AuthCheckCurrentUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        userProvider.setUser(user);
        emit(
          user.isEmailVerified
              ? AuthAuthenticated(user: user)
              : AuthEmailUnverified(user: user),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      userProvider.setUser(user);
      emit(
        user.isEmailVerified
            ? AuthAuthenticated(user: user)
            : AuthEmailUnverified(user: user),
      );
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      userProvider.setUser(user);
      await authRepository.sendVerificationEmail();
      emit(AuthEmailUnverified(user: user));
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      userProvider.clearUser();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> _onSendVerificationEmail(
    AuthSendVerificationEmail event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.sendVerificationEmail();
      final user = userProvider.user;
      if (user != null) emit(AuthVerificationEmailSent(user: user));
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> _onCheckEmailVerified(
    AuthCheckEmailVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final verified = await authRepository.checkEmailVerified();
      if (verified) {
        userProvider.updateEmailVerified();
        final user = userProvider.user!;
        emit(AuthAuthenticated(user: user));
      } else {
        final user = userProvider.user!;
        emit(AuthEmailUnverified(user: user));
      }
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  Future<void> _onSendPasswordReset(
    AuthSendPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordReset(email: event.email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: _parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-credential') || msg.contains('wrong-password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('weak-password')) {
      return 'La contraseña es muy débil.';
    }
    if (msg.contains('user-not-found')) {
      return 'No existe una cuenta con este correo.';
    }
    if (msg.contains('network')) {
      return 'Error de conexión. Revisa tu internet.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
