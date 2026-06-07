import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
      if (Platform.isAndroid)
        Permission.notification,
      if (Platform.isAndroid)
        Permission.phone,
    ].request();
  }
}