import '../repository/call_repository.dart';

class HangupCallUseCase {
  final CallRepository repository;

  HangupCallUseCase(this.repository);

  Future<void> call(
      String sessionId,
      ) {
    return repository.hangup(
      sessionId,
    );
  }
}