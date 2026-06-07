import '../repository/call_repository.dart';

class LoginUseCase {
  final CallRepository repository;

  LoginUseCase(this.repository);

  Future<bool> call({
    required String email,
    required String password,
  }) {
    return repository.login(
      email: email,
      password: password,
    );
  }
}