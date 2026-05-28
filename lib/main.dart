import 'package:app/services/auth_manager.dart';
import 'package:app/services/quickblox_call_service.dart';
import 'package:app/services/quickblox_service.dart';
import 'package:app/views/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';


// Future<void> firebaseBackgroundHandler(RemoteMessage message,) async {
//
//   await Firebase.initializeApp();
//
//   print("BACKGROUND MESSAGE");
//
//   final data = message.data;
//
//   if (data['type'] == 'incoming_call') {
//
//     await QuickBloxService.instance.showIncomingCallKit(
//       sessionId: data['sessionId'],
//       callerName: data['userName'],
//       callerId: data['callerId'],
//     );
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthManager.instance.appLoggedInListener.addListener(()async{
    if(AuthManager.instance.isLoggedIn){
      await QuickBloxService.instance.init();
      await QuickBloxService.instance.login(
          email: AuthManager.instance.email,
          password: AuthManager.instance.password
      );
      AppCallListener.init();
    }else{
      await QuickBloxService.instance.logout();
    }
  });
  // FirebaseMessaging.onBackgroundMessage(
  //   firebaseBackgroundHandler,
  // );
  // FirebaseMessaging.onMessage.listen((message) async {
  //
  //   final data = message.data;
  //
  //   if (data['type'] == 'incoming_call') {
  //
  //     await QuickBloxService.instance.showIncomingCallKit(
  //       sessionId: data['sessionId'],
  //       callerName: data['userName'],
  //       callerId: data['callerId'],
  //     );
  //   }
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}