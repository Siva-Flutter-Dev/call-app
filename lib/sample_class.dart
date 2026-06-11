import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'Messages',
    description: 'Message Notifications',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse:
      notificationTapBackground,
    );

    await notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void notificationTapBackground(
      NotificationResponse response) {
    NotificationRouter.handle(response.payload);
  }

  void _onTap(NotificationResponse response) {
    NotificationRouter.handle(response.payload);
  }

  Future<void> showChatNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    await notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.max,
          priority: Priority.high,
          groupKey: "chat_group",
          category: AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );

    await notifications.show(
      0,
      "Messages",
      "New Messages",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          setAsGroupSummary: true,
          groupKey: "chat_group",
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:get/get.dart';

class NotificationRouter {
  static void handle(String? payload) {
    if (payload == null) return;

    final data = jsonDecode(payload);

    final type = data["type"];

    switch (type) {
      case "chat":
        Get.toNamed(
          "/chat",
          arguments: {
            "chatId": data["chat_id"],
          },
        );
        break;

      case "call":
        Get.toNamed(
          "/call",
          arguments: data,
        );
        break;
    }
  }
}

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final instance =
  FirebaseNotificationService._();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(
      _handleMessage,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpen,
    );

    final initial =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initial != null) {
      _handleOpen(initial);
    }
  }

  void _handleOpen(RemoteMessage message) {
    NotificationRouter.handle(
      jsonEncode(message.data),
    );
  }

  Future<void> _handleMessage(
      RemoteMessage message,
      ) async {
    final data = message.data;

    await NotificationService.instance.showChatNotification(
      title: data["sender_name"] ?? "",
      body: data["message"] ?? "",
      payload: data,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {

  await Firebase.initializeApp();

  await NotificationService.instance.initialize();

  await NotificationService.instance.showChatNotification(
    title: message.data["sender_name"] ?? "",
    body: message.data["message"] ?? "",
    payload: message.data,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.instance.initialize();

  await FirebaseNotificationService.instance.init();

  runApp(
    GetMaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      home: const SplashScreen(),
    ),
  );
}