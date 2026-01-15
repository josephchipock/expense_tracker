// lib/blocs/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../config/supabase_config.dart';
import '../../repositories/database_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DatabaseRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    // Escuchar cambios de autenticación
    SupabaseConfig.authStateChanges.listen((authState) {
      if (authState.session != null) {
        add(AuthCheckRequested());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = SupabaseConfig.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Error inesperado al iniciar sesión'));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await SupabaseConfig.client.auth.signUp(
        email: event.email,
        password: event.password,
      );

      // Inicializar categorías predefinidas
      await repository.initializePredefinedCategories();

      final user = SupabaseConfig.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Error inesperado al registrarse'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await SupabaseConfig.client.auth.signOut();
    emit(AuthUnauthenticated());
  }
}
