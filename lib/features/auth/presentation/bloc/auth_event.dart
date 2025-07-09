import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SendResetPasswordLink extends AuthEvent {
  final String email;
  final String resetUrl;
  final bool isMobile;

  const SendResetPasswordLink({
    required this.email,
    required this.resetUrl,
    this.isMobile = false,
  });

  @override
  List<Object> get props => [email, resetUrl]; // Changé à Object
}

class ResetPassword extends AuthEvent {
  final String email;
  final String token;
  final String password;
  final String passwordConfirmation;

  const ResetPassword({
    required this.email,
    required this.token,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object> get props => [email, token, password, passwordConfirmation]; // Changé à Object
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}
