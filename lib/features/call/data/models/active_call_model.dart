import '../../domain/entities/active_call_entity.dart';

class ActiveCallModel extends ActiveCall {
  const ActiveCallModel({
    required super.sessionId,
    required super.remoteUserId,
    required super.remoteName,
    required super.isVideo,
    required super.direction,
  });

  factory ActiveCallModel.fromIncoming({
    required String sessionId,
    required int remoteUserId,
    required String remoteName,
    required bool isVideo,
    required CallDirection direction,
  }) {
    return ActiveCallModel(
      sessionId: sessionId,
      remoteUserId: remoteUserId,
      remoteName: remoteName,
      isVideo: isVideo,
      direction: direction,
    );
  }
}