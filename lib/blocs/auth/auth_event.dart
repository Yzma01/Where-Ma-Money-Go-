abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSendVerificationEmail extends AuthEvent {}

class AuthCheckEmailVerified extends AuthEvent {}

class AuthSendPasswordReset extends AuthEvent {
  final String email;
  AuthSendPasswordReset({required this.email});
}

class AuthCheckCurrentUser extends AuthEvent {}
