import 'package:where_ma_money_go/models/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthEmailUnverified extends AuthState {
  final UserModel user;
  AuthEmailUnverified({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthVerificationEmailSent extends AuthState {
  final UserModel user;
  AuthVerificationEmailSent({required this.user});
}

class AuthPasswordResetSent extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
