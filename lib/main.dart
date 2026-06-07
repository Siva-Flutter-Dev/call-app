import 'package:app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:app/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'core/di/injection.dart';
import 'core/services/callkit_service.dart';
import 'core/services/permission_service.dart';
import 'features/call/data/datasource/quickbox_datasource.dart';
import 'features/call/presentation/bloc/auth/auth_bloc.dart';
import 'features/call/presentation/bloc/call/call_bloc.dart';
import 'features/call/presentation/bloc/control/call_control_bloc.dart';
import 'features/call/presentation/screens/login_screen.dart';


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
  await AppPrefs.instance.init();

  await initInjection();

  await sl<CallKitService>().initialize();

  await sl<PermissionService>().requestPermissions();

  await sl<QuickBloxDataSource>().initialize();

  // AuthManager.instance.appLoggedInListener.addListener(()async{
  //   if(AuthManager.instance.isLoggedIn){
  //     await QuickBloxService.instance.init();
  //     await QuickBloxService.instance.login(
  //         email: AuthManager.instance.email,
  //         password: AuthManager.instance.password
  //     );
  //     AppCallListener.init();
  //   }else{
  //     await QuickBloxService.instance.logout();
  //   }
  // });
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
    return MultiBlocProvider(
      providers: [

        BlocProvider(
          create: (_) => sl<AuthBloc>(),
        ),

        BlocProvider(
          create: (_) => sl<CallBloc>(),
        ),

        BlocProvider(
          create: (_) => sl<ChatBloc>(),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
      ),
    );
  }
}