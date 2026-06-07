import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/repository/call_repository.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final CallRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_login);

    on<LogoutRequested>(_logout);
  }

  Future<void> _login(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final result = await loginUseCase(
        email: event.email,
        password: event.password,
      );

      if (result) {
        emit(Authenticated());
      } else {
        emit(
          AuthError(
            'Login failed',
          ),
        );
      }
    } catch (e) {
      emit(
        AuthError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> _logout(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await repository.logout();

    emit(
      UnAuthenticated(),
    );
  }
}