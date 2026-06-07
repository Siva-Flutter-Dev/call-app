import '../repository/call_repository.dart';

class StartCallUseCase {
  final CallRepository repository;

  StartCallUseCase(this.repository);

  Future<String?> call({
    required List<int> opponents,
    required bool isVideo,
    required String userName,
  }) {
    return repository.startCall(
      opponents: opponents,
      isVideo: isVideo,
      userName: userName,
    );
  }
}