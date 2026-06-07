import '../repository/call_repository.dart';

class RejectCallUseCase {
  final CallRepository repository;

  RejectCallUseCase(this.repository);

  Future<void> call(
      String sessionId,
      ) {
    return repository.rejectCall(
      sessionId,
    );
  }
}