import 'package:app/services/quickblox_service.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';


class AppCallListener {

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
  }
}