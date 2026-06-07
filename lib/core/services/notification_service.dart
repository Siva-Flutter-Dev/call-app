import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();

    await FirebaseMessaging.instance.getToken();
  }
}