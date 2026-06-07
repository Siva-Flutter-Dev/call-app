sealed class CallKitAction {}

final class CallAcceptedAction extends CallKitAction {
  final String sessionId;

  CallAcceptedAction(this.sessionId);
}

final class CallRejectedAction extends CallKitAction {
  final String sessionId;

  CallRejectedAction(this.sessionId);
}

final class CallEndedAction extends CallKitAction {
  final String sessionId;

  CallEndedAction(this.sessionId);
}