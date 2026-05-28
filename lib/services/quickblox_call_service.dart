import 'dart:async';

import 'package:app/services/quickblox_service.dart';
import 'package:get/get.dart';

import '../views/incoming_screen.dart';

class AppCallListener {
  static StreamSubscription? _incomingSub;
  static StreamSubscription? _callStateSub;

  static void init() {
    _incomingSub ??=
        QuickBloxService.instance.onIncomingCall.listen(
              (event) {
            final sessionId = event['sessionId'];
            final callerId = event['callerId'];
            final userName = event['userName'];

            Get.to(
                IncomingCallScreen(
                  sessionId: sessionId,
                  remoteId: callerId,
                  userName: userName,
                  isVideo: true,
                )
            );
          },
        );

    _callStateSub ??=
        QuickBloxService.instance.onCallState.listen(
              (event) {
            final type = event['type'];

            switch (type) {
              case 'accepted':
                break;

              case 'rejected':
                Get.back();
                break;

              case 'hangup':
                Get.back();
                break;

              case 'not_answer':
                Get.back();
                break;
            }
          },
        );
  }

  static Future<void> dispose() async {
    await _incomingSub?.cancel();
    await _callStateSub?.cancel();

    _incomingSub = null;
    _callStateSub = null;
  }
}
