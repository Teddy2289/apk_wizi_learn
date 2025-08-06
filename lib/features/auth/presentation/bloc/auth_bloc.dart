import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:wizi_learn/core/exceptions/auth_exception.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository_contract.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryContract authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<SendResetPasswordLink>(_onSendResetPasswordLink);
    on<ResetPassword>(_onResetPassword);
    on<RefreshUserRequested>(_onRefreshUserRequested);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(Unauthenticated());
    } on TimeoutException {
      emit(AuthError('Timeout: Le serveur a mis trop de temps à répondre'));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Une erreur inattendue est survenue: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } on AuthException {
      // Même en cas d'erreur, on considère l'utilisateur comme déconnecté
      emit(Unauthenticated());
    } catch (e) {
      // On force la déconnexion même en cas d'erreur inattendue
      emit(Unauthenticated());
    }
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await authRepository.isLoggedIn().timeout(
        const Duration(seconds: 5),
      );

      if (!isLoggedIn) {
        emit(Unauthenticated());
        return;
      }

      final user = await authRepository.getMe().timeout(
        const Duration(seconds: 5),
      );

      emit(Authenticated(user));
    } on TimeoutException {
      emit(
        AuthError('Timeout: Vérification de l\'authentification trop longue'),
      );
      emit(Unauthenticated());
    } on AuthException catch (e) {
      // Si getMe échoue avec une AuthException, on déconnecte proprement
      await authRepository.logout();
      emit(AuthError(e.message));
      emit(Unauthenticated());
    } catch (e) {
      emit(
        AuthError('Erreur inattendue lors de la vérification: ${e.toString()}'),
      );
      emit(Unauthenticated());
    }
  }

  Future<void> _onSendResetPasswordLink(
    SendResetPasswordLink event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendResetPasswordLink(
        event.email,
        event.resetUrl,
        isMobile: event.isMobile,
      );
      emit(ResetLinkSentSuccess());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Erreur inattendue: ${e.toString()}'));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(
        email: event.email,
        token: event.token,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      emit(PasswordResetSuccess());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Erreur inattendue: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshUserRequested(
    RefreshUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getMe();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Erreur lors du rafraîchissement du profil: \n' + e.toString()));
    }
  }
}
