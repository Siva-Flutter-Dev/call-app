import 'package:app/services/quickblox_service.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';


class AppCallListener {
  // static StreamSubscription? _incomingSub;
  // static StreamSubscription? _callStateSub;

  static bool _initialized = false;

  static void init() {

    if (_initialized) return;

    _initialized = true;
    QuickBloxService.instance.onIncomingCall.listen((call) {
      print('Incoming call from ${call.remoteName}');
      // CallKit UI is already shown - handle additional app logic if needed
    });
// Listen for call state changes
    QuickBloxService.instance.onCallState.listen((event) {
      switch (event['type']) {
        case 'connected':
          print('Call connected');
          break;
        case 'hangup':
          print('Call ended');
          // Navigate back from call screen
          Get.back();
          break;
        case 'rejected':
          print('Call rejected');
          Get.back();
          break;
        case 'no_answer':
          print('No answer');
          Get.back();
          break;
        case 'timeout':
          print('Call timed out');
          Get.back();
          break;
      }
    });

    // _incomingSub =
    //     QuickBloxService.instance.onIncomingCall.listen(
    //           (event) async {
    //
    //         final String? sessionId =
    //         event['sessionId']?.toString();
    //
    //         final String callerId =
    //             event['callerId']?.toString() ?? '';
    //
    //         final String userName =
    //             event['userName']?.toString() ?? 'Calling';
    //
    //         if (sessionId == null || sessionId.isEmpty) {
    //           return;
    //         }
    //
    //         // await QuickBloxService.instance.showIncomingCallKit(
    //         //   sessionId: sessionId,
    //         //   callerName: userName,
    //         //   callerId: callerId,
    //         // );
    //
    //         /// OPTIONAL SCREEN
    //         Get.to(
    //           IncomingCallScreen(
    //             sessionId: sessionId,
    //             remoteId: int.tryParse(callerId) ?? 0,
    //             userName: userName,
    //             isVideo: true,
    //           ),
    //         );
    //       },
    //     );
    //
    // _callStateSub =
    //     QuickBloxService.instance.onCallState.listen(
    //           (event) {
    //
    //         final String type =
    //             event['type']?.toString() ?? '';
    //
    //         switch (type) {
    //
    //           case 'accepted':
    //             break;
    //
    //           case 'rejected':
    //             break;
    //
    //           case 'hangup':
    //             break;
    //
    //           case 'not_answer':
    //             break;
    //         }
    //       },
    //     );
  }

  // static Future<void> dispose() async {
  //
  //   await _incomingSub?.cancel();
  //   await _callStateSub?.cancel();
  //
  //   _incomingSub = null;
  //   _callStateSub = null;
  //
  //   _initialized = false;
  // }
}