import '../../../domain/entities/active_call_entity.dart';

abstract class CallState {}

class CallInitial extends CallState {}

class CallLoading extends CallState {}

class IncomingCallKitShown extends CallState {}

class ConnectingCall extends CallState {}

class OutgoingCallState extends CallState {
  final String sessionId;

  OutgoingCallState(
      this.sessionId,
      );
}

class AudioCallStarted extends CallState {
  final ActiveCall call;

  AudioCallStarted(
      this.call,
      );
}

class VideoCallStarted extends CallState {
  final ActiveCall call;

  VideoCallStarted(
      this.call,
      );
}

class CallEnded extends CallState {}

class CallRejected extends CallState {}

class CallError extends CallState {
  final String message;

  CallError(
      this.message,
      );
}