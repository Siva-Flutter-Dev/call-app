import '../repository/call_repository.dart';

class AcceptCallUseCase {
  final CallRepository repository;

  AcceptCallUseCase(this.repository);

  Future<void> call(
      String sessionId,
      ) {
    return repository.acceptCall(
      sessionId,
    );
  }
}