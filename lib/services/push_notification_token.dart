import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quickblox_sdk/push/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

Future<void> subscribePush() async {
  try {
    String? token;
    String channel = '';

    if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
      channel = QBPushChannelNames.GCM;
    } else if (Platform.isIOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
      channel = QBPushChannelNames.APNS;
    }

    if (token != null) {
      await QB.subscriptions.create(
        token,
        channel,
      );

      print('Push subscribed');
    }
  } catch (e) {
    print(e);
  }
}

test(){
  FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
      await QB.subscriptions.create(
        newToken,
        QBPushChannelNames.GCM,
      );
    },
  );
}