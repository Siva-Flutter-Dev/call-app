import 'dart:async';

import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../features/call/domain/entities/active_call_entity.dart';
import 'callkit_actions.dart';

class CallKitService {
  final _controller =
  StreamController<CallKitAction>.broadcast();

  Stream<CallKitAction> get events =>
      _controller.stream;

  Future<void> initialize() async {
    FlutterCallkitIncoming.onEvent.listen(
          (event) {
        if (event == null) return;

        final sessionId =
            event.body['id']?.toString() ?? '';

        switch (event.event) {
          case Event.actionCallAccept:
            _controller.add(
              CallAcceptedAction(sessionId),
            );
            break;

          case Event.actionCallDecline:
            _controller.add(
              CallRejectedAction(sessionId),
            );
            break;

          case Event.actionCallEnded:
            _controller.add(
              CallEndedAction(sessionId),
            );
            break;

          default:
            break;
        }
      },
    );
  }

  Future<void> showIncomingCall(
      ActiveCall call,
      ) async {
    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: call.sessionId,
        nameCaller: call.remoteName,
        appName: 'BotzUp',
        handle: call.remoteUserId.toString(),
        type: call.isVideo ? 1 : 0,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowFullLockedScreen: true,
        ),
        ios: const IOSParams(
          supportsVideo: true,
        ),
      ),
    );
  }

  Future<void> showOutgoingCall(
      ActiveCall call,
      ) async {
    await FlutterCallkitIncoming.startCall(
      CallKitParams(
        id: call.sessionId,
        nameCaller: call.remoteName,
        appName: 'BotzUp',
        handle: call.remoteUserId.toString(),
        type: call.isVideo ? 1 : 0,
      ),
    );
  }

  Future<void> endCall(
      String sessionId,
      ) async {
    await FlutterCallkitIncoming.endCall(
      sessionId,
    );
  }

  Future<void> setConnected(
      String sessionId,
      ) async {
    await FlutterCallkitIncoming
        .setCallConnected(
      sessionId,
    );
  }
}