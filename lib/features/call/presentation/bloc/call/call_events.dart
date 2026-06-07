import '../../../domain/entities/active_call_entity.dart';

abstract class CallEvent {}

class ListenIncomingCalls extends CallEvent {}

class IncomingCallReceived extends CallEvent {
  final ActiveCall call;

  IncomingCallReceived(
      this.call,
      );
}

class StartOutgoingCall extends CallEvent {
  final List<int> opponents;
  final bool isVideo;
  final String userName;

  StartOutgoingCall({
    required this.opponents,
    required this.isVideo,
    required this.userName,
  });
}

class AcceptCallRequested extends CallEvent {
  final String sessionId;

  AcceptCallRequested(
      this.sessionId,
      );
}

class RejectCallRequested extends CallEvent {
  final String sessionId;

  RejectCallRequested(
      this.sessionId,
      );
}

class HangupRequested extends CallEvent {
  final String sessionId;

  HangupRequested(
      this.sessionId,
      );
}

class CallAcceptedByRemote extends CallEvent {}

class CallRejectedByRemote extends CallEvent {}

class CallEndedByRemote extends CallEvent {}