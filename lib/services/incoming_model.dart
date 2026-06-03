class IncomingCallModel {
  final String sessionId;
  final int callerId;
  final String callerName;
  final bool isVideo;

  IncomingCallModel({
    required this.sessionId,
    required this.callerId,
    required this.callerName,
    required this.isVideo,
  });

  factory IncomingCallModel.fromJson(
      Map<String, dynamic> json) {
    return IncomingCallModel(
      sessionId: json['sessionId'],
      callerId: int.parse(json['callerId']),
      callerName: json['callerName'],
      isVideo: json['isVideo'] == "true",
    );
  }
}

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message,) async {
//
//   await Firebase.initializeApp();
//
//   if (message.data['type'] == 'incoming_call') {
//
//     await CallKitService.showIncomingCall(
//       sessionId: message.data['sessionId'],
//       callerName: message.data['callerName'],
//       callerId: message.data['callerId'],
//       isVideo: message.data['isVideo'] == 'true',
//     );
//   }
// }

// FirebaseMessaging.onMessage.listen(
// (message) async {
//
// if (message.data['type'] == 'incoming_call') {
//
// await CallKitService.showIncomingCall(
// sessionId: message.data['sessionId'],
// callerName: message.data['callerName'],
// callerId: message.data['callerId'],
// isVideo: true,
// );
// }
// },
// );
// WidgetsFlutterBinding.ensureInitialized();
//
// await Firebase.initializeApp();
//
// FirebaseMessaging.onBackgroundMessage(
// firebaseMessagingBackgroundHandler,
// );