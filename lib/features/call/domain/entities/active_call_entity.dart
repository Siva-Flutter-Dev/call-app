import 'package:equatable/equatable.dart';

enum CallDirection {
  incoming,
  outgoing,
}

class ActiveCall extends Equatable {
  final String sessionId;

  final int remoteUserId;

  final String remoteName;

  final bool isVideo;

  final CallDirection direction;

  const ActiveCall({
    required this.sessionId,
    required this.remoteUserId,
    required this.remoteName,
    required this.isVideo,
    required this.direction,
  });

  @override
  List<Object?> get props => [
    sessionId,
    remoteUserId,
    remoteName,
    isVideo,
    direction,
  ];
}