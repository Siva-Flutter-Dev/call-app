// import 'dart:async';
// import 'package:app/views/video_call.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_event.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:quickblox_sdk/auth/constants.dart';
// import 'package:quickblox_sdk/auth/module.dart';
// import 'package:quickblox_sdk/models/qb_session.dart';
// import 'package:quickblox_sdk/quickblox_sdk.dart';
// import 'package:quickblox_sdk/webrtc/constants.dart';
//
// class QuickBloxService with WidgetsBindingObserver {
//   QuickBloxService._();
//
//   static final QuickBloxService instance = QuickBloxService._();
//
//   int? currentUserId;
//
//   String? _email;
//   String? _password;
//
//   String? activeSessionId;
//   int? remoteUserId;
//
//   bool _isInitialized = false;
//   bool _isLoggedIn = false;
//   bool _isConnecting = false;
//   bool _manualLogout = false;
//   bool _rtcSubscribed = false;
//   bool _callkitInitialized = false;
//
//   Timer? _reconnectTimer;
//
//   final StreamController<Map<String, dynamic>> _incomingCallController = StreamController.broadcast();
//
//   final StreamController<Map<String, dynamic>> _callStateController = StreamController.broadcast();
//
//   final StreamController<bool> _connectionStateController = StreamController.broadcast();
//
//   Stream<Map<String, dynamic>> get onIncomingCall => _incomingCallController.stream;
//
//   Stream<Map<String, dynamic>> get onCallState => _callStateController.stream;
//
//   Stream<bool> get onConnectionChanged => _connectionStateController.stream;
//
//   bool get isLoggedIn => _isLoggedIn;
//
//   Future<void> init() async {
//     if (_isInitialized) return;
//
//     try {
//       WidgetsBinding.instance.addObserver(this);
//
//       await _requestPermissions();
//
//       await QB.settings.init(
//         appId,
//         authKey,
//         authSecret,
//         accountKey,
//       );
//
//       await QB.settings.enableLogging();
//       await QB.settings.enableXMPPLogging();
//
//       await _initializeCallKit();
//
//       await _subscribeRTCEvents();
//
//       _isInitialized = true;
//
//       debugPrint('QuickBlox Initialized');
//     } on PlatformException catch (e) {
//       debugPrint('QB Init Error => ${e.message}');
//     }
//   }
//
//   Future<bool> login({
//     required String email,
//     required String password,
//   }) async {
//     if (_isConnecting) return false;
//
//     _isConnecting = true;
//     _manualLogout = false;
//
//     try {
//       _email = email;
//       _password = password;
//
//       final QBLoginResult result =
//       await QB.auth.loginWithEmail(email, password);
//
//       currentUserId = result.qbUser?.id;
//
//       if (currentUserId == null) {
//         throw Exception('User ID is null');
//       }
//
//       final connected = await QB.chat.isConnected();
//
//       if (connected==false) {
//         await QB.chat.connect(currentUserId!, password);
//       }
//
//       await QB.webrtc.init();
//
//       _listenSessionExpiry();
//
//       _isLoggedIn = true;
//
//       _connectionStateController.add(true);
//
//       debugPrint('QB Login Success => $currentUserId');
//
//       return true;
//     } catch (e) {
//       debugPrint('QB Login Error => $e');
//
//       _startReconnect();
//
//       return false;
//     } finally {
//       _isConnecting = false;
//     }
//   }
//
//   Future<void> logout() async {
//     _manualLogout = true;
//
//     try {
//       _reconnectTimer?.cancel();
//
//       await endAllCalls();
//
//       final connected = await QB.chat.isConnected();
//
//       if (connected==true) {
//         await QB.chat.disconnect();
//       }
//
//       await QB.auth.logout();
//     } catch (e) {
//       debugPrint('Logout Error => $e');
//     }
//
//     _clearAllState();
//   }
//
//   Future<String?> startCall({
//     required List<int> opponentIds,
//     required String userName,
//     bool isVideo = true,
//   }) async {
//     try {
//       await QB.webrtc.init();
//       final session = await QB.webrtc.call(
//         opponentIds,
//         isVideo
//             ? QBRTCSessionTypes.VIDEO
//             : QBRTCSessionTypes.AUDIO,
//         userInfo: {
//           'userName': userName,
//           'callerId':opponentIds.first.toString()
//         },
//       );
//
//       activeSessionId = session?.id;
//       remoteUserId = opponentIds.first;
//
//       if (activeSessionId != null) {
//         // await _startOutgoingCallKit(
//         //   sessionId: activeSessionId!,
//         //   userName: userName,
//         //   userId: remoteUserId.toString(),
//         //   isVideo: isVideo,
//         // );
//         Get.to(VideoCallScreen(
//             sessionId: activeSessionId!,
//             userName: userName,
//             remoteId: remoteUserId??0,
//             currentUserId: currentUserId??0));
//       }
//
//       debugPrint('Call Started => $activeSessionId');
//
//       return activeSessionId;
//     } catch (e) {
//       debugPrint('Start Call Error => $e');
//       return null;
//     }
//   }
//
//   Future<void> acceptCall({required String sessionId,}) async {
//     try {
//       await QB.webrtc.accept(sessionId, userInfo: {});
//
//       activeSessionId = sessionId;
//
//       await FlutterCallkitIncoming.setCallConnected(sessionId);
//
//       _callStateController.add({
//         'type': 'accepted',
//         'sessionId': sessionId,
//       });
//
//       debugPrint('Call Accepted');
//     } catch (e) {
//       debugPrint('Accept Call Error => $e');
//     }
//   }
//
//   Future<void> rejectCall(String sessionId) async {
//     try {
//       await QB.webrtc.reject(sessionId, userInfo: {});
//
//       await FlutterCallkitIncoming.endCall(sessionId);
//
//       clearCallState();
//
//       _callStateController.add({
//         'type': 'rejected',
//         'sessionId': sessionId,
//       });
//
//       debugPrint('Call Rejected');
//     } catch (e) {
//       debugPrint('Reject Call Error => $e');
//     }
//   }
//
//   Future<void> hangUp(String sessionId) async {
//     try {
//       await QB.webrtc.hangUp(sessionId, userInfo: {});
//
//       await FlutterCallkitIncoming.endCall(sessionId);
//
//       clearCallState();
//
//       _callStateController.add({
//         'type': 'hangup',
//         'sessionId': sessionId,
//       });
//
//       debugPrint('Call Ended');
//     } catch (e) {
//       debugPrint('Hangup Error => $e');
//     }
//   }
//
//   Future<void> setAudioEnabled({required String sessionId, required bool enabled,}) async {
//     try {
//       await QB.webrtc.enableAudio(
//         sessionId,
//         enable: enabled,
//       );
//     } catch (e) {
//       debugPrint('Audio Toggle Error => $e');
//     }
//   }
//
//   Future<void> setVideoEnabled({required String sessionId, required bool enabled,}) async {
//     try {
//       await QB.webrtc.enableVideo(
//         sessionId,
//         enable: enabled,
//       );
//     } catch (e) {
//       debugPrint('Video Toggle Error => $e');
//     }
//   }
//
//   Future<void> switchCamera(String sessionId) async {
//     try {
//       await QB.webrtc.switchCamera(sessionId);
//     } catch (e) {
//       debugPrint('Switch Camera Error => $e');
//     }
//   }
//
//   Future<void> switchAudioOutput(int output) async {
//     try {
//       await QB.webrtc.switchAudioOutput(output);
//     } catch (e) {
//       debugPrint('Switch Audio Error => $e');
//     }
//   }
//
//   Future<void> _subscribeRTCEvents() async {
//     if (_rtcSubscribed) return;
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.CALL,
//           (data) async {
//         final sessionId = _extractSessionId(data);
//         final callerId = _extractCallerId(data);
//         final userName = _extractUserName(data);
//
//         if (sessionId == null || callerId == null) return;
//
//         activeSessionId = sessionId;
//         remoteUserId = callerId;
//
//         // await showIncomingCallKit(
//         //   sessionId: sessionId,
//         //   callerName: userName ?? 'Calling',
//         //   callerId: callerId.toString(),
//         // );
//
//         _incomingCallController.add({
//           'sessionId': sessionId,
//           'callerId': callerId,
//           'userName': userName,
//         });
//
//         debugPrint('Incoming Call => $sessionId');
//       },
//     );
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.ACCEPT,
//           (data) {
//         _callStateController.add({
//           'type': 'accepted',
//           'data': data,
//         });
//       },
//     );
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.REJECT,
//           (data) async {
//         await endAllCalls();
//
//         clearCallState();
//
//         _callStateController.add({
//           'type': 'rejected',
//           'data': data,
//         });
//       },
//     );
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.HANG_UP,
//           (data) async {
//         await endAllCalls();
//
//         clearCallState();
//
//         _callStateController.add({
//           'type': 'hangup',
//           'data': data,
//         });
//       },
//     );
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.NOT_ANSWER,
//           (data) async {
//         await endAllCalls();
//
//         clearCallState();
//
//         _callStateController.add({
//           'type': 'not_answer',
//           'data': data,
//         });
//       },
//     );
//
//     QB.webrtc.subscribeRTCEvent(
//       QBRTCEventTypes.RECEIVED_VIDEO_TRACK,
//           (data) {
//         _callStateController.add({
//           'type': 'video_track',
//           'data': data,
//         });
//       },
//     );
//
//     _rtcSubscribed = true;
//   }
//
//   Future<void> _initializeCallKit() async {
//     if (_callkitInitialized) return;
//
//     FlutterCallkitIncoming.onEvent.listen((event) async {
//       if (event == null) return;
//
//       final body = event.body;
//
//       final sessionId = body['id'];
//       final Map<String, dynamic> extra = Map<String, dynamic>.from(body['extra'] ?? {});
//
//       final String callerId = extra['callerId']?.toString() ?? '';
//       final String userName = extra['userName']?.toString() ?? 'Calling';
//
//       switch (event.event) {
//         case Event.actionCallAccept:
//           if (sessionId != null) {
//             await acceptCall(sessionId: sessionId);
//           }
//           break;
//
//         case Event.actionCallIncoming:
//           debugPrint("Event ==> ${event.event}");
//           _incomingCallController.add({
//             'sessionId': sessionId,
//             'callerId': callerId,
//             'userName': userName,
//           });
//           break;
//
//         case Event.actionCallDecline:
//           if (sessionId != null) {
//             await rejectCall(sessionId);
//           }
//           break;
//
//         case Event.actionCallEnded:
//           if (sessionId != null) {
//             await hangUp(sessionId);
//           }
//           break;
//
//         default:
//           break;
//       }
//     });
//
//     _callkitInitialized = true;
//   }
//
//   Future<void> showIncomingCallKit({required String sessionId, required String callerName, required String callerId, bool isVideo = true,}) async {
//     await FlutterCallkitIncoming.endAllCalls();
//
//     final params = CallKitParams(
//       id: sessionId,
//       nameCaller: callerName,
//       appName: 'BotzUp',
//       handle: callerId,
//       type: isVideo ? 1 : 0,
//       duration: 30000,
//       textAccept: 'Accept',
//       textDecline: 'Decline',
//       extra: {
//         'callerId': callerId,
//         'userName': callerName,
//       },
//       android: AndroidParams(
//         isCustomNotification: true,
//         isShowLogo: false,
//         isShowCallID: false,
//
//         ringtonePath: 'system_ringtone_default',
//
//         backgroundColor: '#0955fa',
//         actionColor: '#4CAF50',
//         textColor: '#ffffff',
//
//         incomingCallNotificationChannelName: callerName,
//         missedCallNotificationChannelName: 'Missed Call',
//       ),
//       ios: const IOSParams(
//         iconName: 'CallKitLogo',
//         supportsVideo: true,
//         maximumCallGroups: 1,
//         maximumCallsPerCallGroup: 1,
//       ),
//     );
//
//     await FlutterCallkitIncoming.showCallkitIncoming(params);
//   }
//
//   Future<void> startOutgoingCallKit({required String sessionId, required String userName, required String userId, bool isVideo = true,}) async {
//     final params = CallKitParams(
//       id: sessionId,
//       nameCaller: userName,
//       appName: 'BotzUp',
//       handle: userId,
//       type: isVideo ? 1 : 0,
//       extra: {
//         'callerId': userId,
//       },
//       android: const AndroidParams(
//         isCustomNotification: true,
//       ),
//       ios: const IOSParams(
//         supportsVideo: true,
//       ),
//     );
//
//     await FlutterCallkitIncoming.startCall(params);
//   }
//
//   void _startReconnect() {
//     if (_manualLogout) return;
//
//     _reconnectTimer?.cancel();
//
//     _reconnectTimer = Timer.periodic(
//       const Duration(seconds: 5),
//           (_) async {
//         try {
//           final alive = await _isSessionAlive();
//
//           if (alive) {
//             _reconnectTimer?.cancel();
//             return;
//           }
//
//           if (_email != null && _password != null) {
//             await login(
//               email: _email!,
//               password: _password!,
//             );
//           }
//         } catch (e) {
//           debugPrint('Reconnect Error => $e');
//         }
//       },
//     );
//   }
//
//   void _listenSessionExpiry() {
//     QB.auth.subscribeAuthEvent(
//       QBAuthEvents.SESSION_EXPIRED,
//           (data) async {
//         debugPrint('Session Expired');
//
//         _isLoggedIn = false;
//
//         _startReconnect();
//       },
//     );
//   }
//
//   Future<bool> _isSessionAlive() async {
//     try {
//       final QBSession? session = await QB.auth.getSession();
//
//       if (session == null) return false;
//
//       if (currentUserId != null &&
//           session.userId != currentUserId) {
//         return false;
//       }
//
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         if (!_manualLogout) {
//           final alive = await _isSessionAlive();
//
//           if (!alive &&
//               _email != null &&
//               _password != null) {
//             await login(
//               email: _email!,
//               password: _password!,
//             );
//           }
//         }
//         break;
//
//       default:
//         break;
//     }
//   }
//
//   /// Helpers
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.microphone,
//       Permission.camera,
//     ].request();
//   }
//
//   String? _extractSessionId(dynamic data) {
//     final payload = data?['payload'] ?? data;
//
//     return payload?['session']?['id']?.toString() ??
//         payload?['sessionId']?.toString();
//   }
//
//   int? _extractCallerId(dynamic data) {
//     final payload = data?['payload'] ?? data;
//
//     final raw = payload?['session']?['initiatorId'] ??
//         payload?['callerId'];
//
//     if (raw == null) return null;
//
//     return raw is int ? raw : int.tryParse(raw.toString());
//   }
//
//   String? _extractUserName(dynamic data) {
//     final payload = data?['payload'] ?? data;
//
//     return payload?['userInfo']?['userName'];
//   }
//
//   Future<void> endAllCalls() async {
//     try {
//       await FlutterCallkitIncoming.endAllCalls();
//     } catch (_) {}
//   }
//
//   void clearCallState() {
//     activeSessionId = null;
//     remoteUserId = null;
//   }
//
//   void _clearAllState() {
//     currentUserId = null;
//
//     activeSessionId = null;
//     remoteUserId = null;
//
//     _isLoggedIn = false;
//     _isConnecting = false;
//
//     _connectionStateController.add(false);
//   }
//
//   Future<void> dispose() async {
//     WidgetsBinding.instance.removeObserver(this);
//
//     _reconnectTimer?.cancel();
//
//     await QB.webrtc.release();
//
//     await endAllCalls();
//
//     await _incomingCallController.close();
//     await _callStateController.close();
//     await _connectionStateController.close();
//   }
// }
//
//
// const String appId = '108053';
// const String authKey = 'ak_qTej96WZDn6eDGJ';
// const String authSecret = 'as_MThb9ZJgj7f9V4e';
// const String accountKey = 'ack_wSHemJsk1e1t1bJYBVbN';

import 'dart:async';
import 'dart:io';

import 'package:app/views/audio_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickblox_sdk/auth/constants.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/webrtc/constants.dart';

// Import your video call screen
import 'package:app/views/video_call.dart';

/// QuickBlox credentials
const String appId = '108053';
const String authKey = 'ak_qTej96WZDn6eDGJ';
const String authSecret = 'as_MThb9ZJgj7f9V4e';
const String accountKey = 'ack_wSHemJsk1e1t1bJYBVbN';

/// Call timeout duration
const Duration kCallTimeout = Duration(seconds: 45);
const Duration kReconnectInterval = Duration(seconds: 5);

/// Call state enum for clean state management
enum CallState {
  idle,
  incoming,
  outgoing,
  connecting,
  connected,
  ending,
}

/// Call direction
enum CallDirection { incoming, outgoing }

/// Active call data model
class ActiveCall {
  final String sessionId;
  final int remoteUserId;
  final String remoteName;
  final CallDirection direction;
  final bool isVideo;
  final DateTime startTime;

  ActiveCall({
    required this.sessionId,
    required this.remoteUserId,
    required this.remoteName,
    required this.direction,
    required this.isVideo,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  ActiveCall copyWith({
    String? sessionId,
    int? remoteUserId,
    String? remoteName,
    CallDirection? direction,
    bool? isVideo,
    DateTime? startTime,
  }) {
    return ActiveCall(
      sessionId: sessionId ?? this.sessionId,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteName: remoteName ?? this.remoteName,
      direction: direction ?? this.direction,
      isVideo: isVideo ?? this.isVideo,
      startTime: startTime ?? this.startTime,
    );
  }
}

class QuickBloxService with WidgetsBindingObserver {
  QuickBloxService._();
  static final QuickBloxService instance = QuickBloxService._();

  // ─────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────

  int? currentUserId;
  String? _email;
  String? _password;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isConnecting = false;
  bool _manualLogout = false;
  bool _rtcSubscribed = false;
  bool _callkitInitialized = false;

  CallState _callState = CallState.idle;
  ActiveCall? _activeCall;

  Timer? _reconnectTimer;
  Timer? _callTimeoutTimer;

  // ─────────────────────────────────────────────────────────────────
  // Stream Controllers
  // ─────────────────────────────────────────────────────────────────

  final _incomingCallController = StreamController<ActiveCall>.broadcast();
  final _callStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<ActiveCall> get onIncomingCall => _incomingCallController.stream;
  Stream<Map<String, dynamic>> get onCallState => _callStateController.stream;
  Stream<bool> get onConnectionChanged => _connectionStateController.stream;

  // ─────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────

  bool get isLoggedIn => _isLoggedIn;
  bool get isInCall => _callState != CallState.idle;
  CallState get callState => _callState;
  ActiveCall? get activeCall => _activeCall;

  // ─────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);

      await _requestPermissions();

      await QB.settings.init(appId, authKey, authSecret, accountKey);
      await QB.settings.enableLogging();
      await QB.settings.enableXMPPLogging();

      await _initializeCallKit();
      await _checkForActiveCallOnLaunch();

      _isInitialized = true;
      debugPrint('[QB] Initialized');
    } on PlatformException catch (e) {
      debugPrint('[QB] Init Error: ${e.message}');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
      if (Platform.isAndroid) Permission.phone,
      if (Platform.isAndroid) Permission.notification,
    ].request();

    statuses.forEach((permission, status) {
      debugPrint('[QB] $permission: $status');
    });
  }

  /// Check if app was launched from a CallKit notification
  Future<void> _checkForActiveCallOnLaunch() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        final call = calls.first;
        debugPrint('[QB] Active call on launch: ${call['id']}');
        // The CallKit event listener will handle this
      }
    } catch (e) {
      debugPrint('[QB] Check active calls error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    if (_isConnecting) {
      debugPrint('[QB] Login already in progress');
      return false;
    }

    _isConnecting = true;
    _manualLogout = false;

    try {
      _email = email;
      _password = password;

      final result = await QB.auth.loginWithEmail(email, password);
      currentUserId = result.qbUser?.id;

      if (currentUserId == null) {
        throw Exception('User ID is null after login');
      }

      // Connect to chat
      final isConnected = await QB.chat.isConnected() ?? false;
      if (!isConnected) {
        await QB.chat.connect(currentUserId!, password);
      }

      // Initialize WebRTC
      await QB.webrtc.init();

      // Subscribe to RTC events after WebRTC init
      await _subscribeRTCEvents();

      // Listen for session expiry
      _listenSessionExpiry();

      _isLoggedIn = true;
      _connectionStateController.add(true);

      debugPrint('[QB] Login success: $currentUserId');
      return true;
    } catch (e) {
      debugPrint('[QB] Login error: $e');
      _scheduleReconnect();
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> logout() async {
    _manualLogout = true;
    _reconnectTimer?.cancel();
    _callTimeoutTimer?.cancel();

    try {
      await _endCurrentCall(reason: 'logout');

      final isConnected = await QB.chat.isConnected() ?? false;
      if (isConnected) {
        await QB.chat.disconnect();
      }

      await QB.webrtc.release();
      await QB.auth.logout();
    } catch (e) {
      debugPrint('[QB] Logout error: $e');
    }

    _clearAllState();
    debugPrint('[QB] Logged out');
  }

  void _listenSessionExpiry() {
    QB.auth.subscribeAuthEvent(QBAuthEvents.SESSION_EXPIRED, (data) async {
      debugPrint('[QB] Session expired');
      _isLoggedIn = false;
      _connectionStateController.add(false);
      _scheduleReconnect();
    });
  }

  void _scheduleReconnect() {
    if (_manualLogout) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(kReconnectInterval, (_) async {
      if (_manualLogout) {
        _reconnectTimer?.cancel();
        return;
      }

      try {
        final alive = await _isSessionAlive();
        if (alive) {
          _reconnectTimer?.cancel();
          _connectionStateController.add(true);
          return;
        }

        if (_email != null && _password != null) {
          debugPrint('[QB] Attempting reconnect...');
          await login(email: _email!, password: _password!);
        }
      } catch (e) {
        debugPrint('[QB] Reconnect error: $e');
      }
    });
  }

  Future<bool> _isSessionAlive() async {
    try {
      final QBSession? session = await QB.auth.getSession();
      if (session == null) return false;
      if (currentUserId != null && session.userId != currentUserId) return false;

      final isConnected = await QB.chat.isConnected() ?? false;
      return isConnected;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CallKit Setup
  // ─────────────────────────────────────────────────────────────────

  Future<void> _initializeCallKit() async {
    if (_callkitInitialized) return;

    FlutterCallkitIncoming.onEvent.listen(_handleCallKitEvent);
    _callkitInitialized = true;
    debugPrint('[QB] CallKit initialized');
  }

  Future<void> _handleCallKitEvent(CallEvent? event) async {
    if (event == null) return;

    final body = event.body as Map<dynamic, dynamic>? ?? {};
    final sessionId = body['id']?.toString();
    final extra = Map<String, dynamic>.from(body['extra'] ?? {});
    final callerId = extra['callerId']?.toString() ?? '';
    final userName = extra['userName']?.toString() ?? 'Unknown';
    final isVideo = (body['type'] ?? 1) == 1;

    debugPrint('[QB] CallKit event: ${event.event}, sessionId: $sessionId');

    switch (event.event) {
      case Event.actionCallIncoming:
      // CallKit is showing the incoming call UI
      // State already set by RTC event, just ensure sync
        if (_activeCall == null && sessionId != null) {
          _setCallState(
            CallState.incoming,
            ActiveCall(
              sessionId: sessionId,
              remoteUserId: int.tryParse(callerId) ?? 0,
              remoteName: userName,
              direction: CallDirection.incoming,
              isVideo: isVideo,
            ),
          );
        }
        break;

      case Event.actionCallAccept:
        if (sessionId != null) {
          await _handleCallAccepted(sessionId);
        }
        break;

      case Event.actionCallDecline:
        if (sessionId != null) {
          await _handleCallDeclined(sessionId);
        }
        break;

      case Event.actionCallEnded:
        if (sessionId != null) {
          await _handleCallEnded(sessionId);
        }
        break;

      case Event.actionCallStart:
      // Outgoing call started via CallKit (iOS)
        debugPrint('[QB] Outgoing call started via CallKit');
        break;

      case Event.actionCallToggleMute:
        final isMuted = body['isMuted'] ?? false;
        if (sessionId != null) {
          await setAudioEnabled(sessionId: sessionId, enabled: !isMuted);
        }
        break;

      case Event.actionCallToggleHold:
      // Handle hold if needed
        break;

      case Event.actionCallToggleDmtf:
      // Handle DTMF if needed
        break;

      case Event.actionCallToggleGroup:
      // Handle group if needed
        break;

      case Event.actionCallToggleAudioSession:
      // Handle audio session toggle
        break;

      case Event.actionDidUpdateDevicePushTokenVoip:
      // Handle VoIP token update
        final token = body['deviceTokenVoIP'];
        debugPrint('[QB] VoIP token: $token');
        break;

      case Event.actionCallCustom:
      // Handle custom actions
        break;

      default:
        debugPrint('[QB] Unhandled CallKit event: ${event.event}');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // RTC Event Subscriptions
  // ─────────────────────────────────────────────────────────────────

  Future<void> _subscribeRTCEvents() async {
    if (_rtcSubscribed) return;

    // Incoming call
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.CALL, _onIncomingCall);

    // Call accepted by remote
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.ACCEPT, _onCallAccepted);

    // Call rejected by remote
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.REJECT, _onCallRejected);

    // Call hung up
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.HANG_UP, _onCallHungUp);

    // No answer
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.NOT_ANSWER, _onNoAnswer);

    // Video track received
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.RECEIVED_VIDEO_TRACK, _onVideoTrack);

    // Peer connection state
    await QB.webrtc.subscribeRTCEvent(QBRTCEventTypes.PEER_CONNECTION_STATE_CHANGED, _onPeerConnectionStateChanged);

    _rtcSubscribed = true;
    debugPrint('[QB] RTC events subscribed');
  }

  void _onIncomingCall(dynamic data) async {
    debugPrint('[QB] RTC: Incoming call - $data');

    final sessionId = _extractSessionId(data);
    final callerId = _extractCallerId(data);
    final userName = _extractUserName(data) ?? 'Incoming Call';
    final isVideo = _extractIsVideo(data);

    if (sessionId == null || callerId == null) {
      debugPrint('[QB] Invalid incoming call data');
      return;
    }

    // Check if already in a call
    if (isInCall && _activeCall?.sessionId != sessionId) {
      debugPrint('[QB] Already in call, rejecting new call');
      await QB.webrtc.reject(sessionId, userInfo: {'reason': 'busy'});
      return;
    }

    final call = ActiveCall(
      sessionId: sessionId,
      remoteUserId: callerId,
      remoteName: userName,
      direction: CallDirection.incoming,
      isVideo: isVideo,
    );

    _setCallState(CallState.incoming, call);

    // Show CallKit incoming call UI
    await _showIncomingCallKit(call);

    // Start call timeout
    _startCallTimeout(sessionId);

    // Emit to stream for app-level handling
    _incomingCallController.add(call);
  }

  void _onCallAccepted(dynamic data) async {
    debugPrint('[QB] RTC: Call accepted - $data');

    final sessionId = _extractSessionId(data);
    if (sessionId == null || _activeCall?.sessionId != sessionId) return;

    _cancelCallTimeout();

    // Update CallKit state
    await FlutterCallkitIncoming.setCallConnected(sessionId);

    _setCallState(CallState.connected, _activeCall);

    _callStateController.add({
      'type': 'connected',
      'sessionId': sessionId,
      'direction': 'outgoing',
    });
  }

  void _onCallRejected(dynamic data) async {
    debugPrint('[QB] RTC: Call rejected - $data');

    final sessionId = _extractSessionId(data);
    if (sessionId == null) return;

    await _cleanupCall(sessionId, 'rejected');

    _callStateController.add({
      'type': 'rejected',
      'sessionId': sessionId,
    });
  }

  void _onCallHungUp(dynamic data) async {
    debugPrint('[QB] RTC: Call hung up - $data');

    final sessionId = _extractSessionId(data);
    if (sessionId == null) return;

    await _cleanupCall(sessionId, 'hungup');

    _callStateController.add({
      'type': 'hangup',
      'sessionId': sessionId,
    });
  }

  void _onNoAnswer(dynamic data) async {
    debugPrint('[QB] RTC: No answer - $data');

    final sessionId = _extractSessionId(data);
    if (sessionId == null) return;

    await _cleanupCall(sessionId, 'no_answer');

    _callStateController.add({
      'type': 'no_answer',
      'sessionId': sessionId,
    });
  }

  void _onVideoTrack(dynamic data) {
    debugPrint('[QB] RTC: Video track received');
    _callStateController.add({
      'type': 'video_track',
      'data': data,
    });
  }

  void _onPeerConnectionStateChanged(dynamic data) {
    debugPrint('[QB] RTC: Peer connection state changed - $data');
    final state = data?['payload']?['state'];

    if (state == 'failed' || state == 'disconnected' || state == 'closed') {
      final sessionId = _activeCall?.sessionId;
      if (sessionId != null) {
        _cleanupCall(sessionId, 'connection_lost');
        _callStateController.add({
          'type': 'connection_lost',
          'sessionId': sessionId,
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Call Actions
  // ─────────────────────────────────────────────────────────────────

  /// Start an outgoing call
  Future<String?> startCall({
    required List<int> opponentIds,
    required String userName,
    bool isVideo = true,
  }) async {
    if (opponentIds.isEmpty) {
      debugPrint('[QB] No opponents specified');
      return null;
    }

    if (isInCall) {
      debugPrint('[QB] Already in a call');
      return null;
    }

    if (!_isLoggedIn) {
      debugPrint('[QB] Not logged in');
      return null;
    }

    try {
      await QB.webrtc.init();

      final session = await QB.webrtc.call(
        opponentIds,
        isVideo ? QBRTCSessionTypes.VIDEO : QBRTCSessionTypes.AUDIO,
        userInfo: {
          'userName': userName,
          'callerId': currentUserId.toString(),
        },
      );

      final sessionId = session?.id;
      if (sessionId == null) {
        throw Exception('Session ID is null');
      }

      final call = ActiveCall(
        sessionId: sessionId,
        remoteUserId: opponentIds.first,
        remoteName: userName,
        direction: CallDirection.outgoing,
        isVideo: isVideo,
      );

      _setCallState(CallState.outgoing, call);

      // Show outgoing call UI via CallKit
      await _showOutgoingCallKit(call);

      // Start call timeout
      _startCallTimeout(sessionId);

      // Navigate to call screen
      _navigateToCallScreen(call);

      debugPrint('[QB] Outgoing call started: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('[QB] Start call error: $e');
      _setCallState(CallState.idle, null);
      return null;
    }
  }

  /// Accept an incoming call
  Future<bool> acceptCall({required String sessionId}) async {
    if (_activeCall?.sessionId != sessionId) {
      debugPrint('[QB] Session mismatch on accept');
      return false;
    }

    try {
      _cancelCallTimeout();
      _setCallState(CallState.connecting, _activeCall);

      await QB.webrtc.accept(sessionId, userInfo: {});

      // Update CallKit
      await FlutterCallkitIncoming.setCallConnected(sessionId);

      _setCallState(CallState.connected, _activeCall);

      // Navigate to call screen
      if (_activeCall != null) {
        _navigateToCallScreen(_activeCall!);
      }

      _callStateController.add({
        'type': 'accepted',
        'sessionId': sessionId,
        'direction': 'incoming',
      });

      debugPrint('[QB] Call accepted: $sessionId');
      return true;
    } catch (e) {
      debugPrint('[QB] Accept call error: $e');
      await _cleanupCall(sessionId, 'accept_error');
      return false;
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(String sessionId) async {
    try {
      _cancelCallTimeout();

      await QB.webrtc.reject(sessionId, userInfo: {'reason': 'declined'});

      await _cleanupCall(sessionId, 'rejected');

      _callStateController.add({
        'type': 'rejected',
        'sessionId': sessionId,
      });

      debugPrint('[QB] Call rejected: $sessionId');
    } catch (e) {
      debugPrint('[QB] Reject call error: $e');
      await _cleanupCall(sessionId, 'reject_error');
    }
  }

  /// Hang up active call
  Future<void> hangUp(String sessionId) async {
    try {
      _cancelCallTimeout();

      await QB.webrtc.hangUp(sessionId, userInfo: {});

      await _cleanupCall(sessionId, 'hangup');

      _callStateController.add({
        'type': 'hangup',
        'sessionId': sessionId,
      });

      debugPrint('[QB] Call hung up: $sessionId');
    } catch (e) {
      debugPrint('[QB] Hangup error: $e');
      await _cleanupCall(sessionId, 'hangup_error');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CallKit Event Handlers (from UI interactions)
  // ─────────────────────────────────────────────────────────────────

  Future<void> _handleCallAccepted(String sessionId) async {
    debugPrint('[QB] CallKit: Call accepted - $sessionId');

    // Ensure we're logged in and connected
    if (!_isLoggedIn) {
      if (_email != null && _password != null) {
        await login(email: _email!, password: _password!);
      } else {
        debugPrint('[QB] Cannot accept call - not logged in');
        await FlutterCallkitIncoming.endCall(sessionId);
        return;
      }
    }

    await acceptCall(sessionId: sessionId);
  }

  Future<void> _handleCallDeclined(String sessionId) async {
    debugPrint('[QB] CallKit: Call declined - $sessionId');
    await rejectCall(sessionId);
  }

  Future<void> _handleCallEnded(String sessionId) async {
    debugPrint('[QB] CallKit: Call ended - $sessionId');

    if (_activeCall?.sessionId == sessionId) {
      if (_callState == CallState.connected ||
          _callState == CallState.connecting) {
        await hangUp(sessionId);
      } else {
        await rejectCall(sessionId);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CallKit UI Methods
  // ─────────────────────────────────────────────────────────────────

  Future<void> _showIncomingCallKit(ActiveCall call) async {
    // End any stale CallKit calls first
    await FlutterCallkitIncoming.endAllCalls();

    final params = CallKitParams(
      id: call.sessionId,
      nameCaller: call.remoteName,
      appName: 'BotzUp',
      handle: call.remoteUserId.toString(),
      type: call.isVideo ? 1 : 0,
      duration: kCallTimeout.inMilliseconds,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed Call',
      ),
      extra: {
        'callerId': call.remoteUserId.toString(),
        'userName': call.remoteName,
        'isVideo': call.isVideo.toString(),
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'videoChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('[QB] Showing incoming CallKit for ${call.sessionId}');
  }

  Future<void> _showOutgoingCallKit(ActiveCall call) async {
    final params = CallKitParams(
      id: call.sessionId,
      nameCaller: call.remoteName,
      appName: 'BotzUp',
      handle: call.remoteUserId.toString(),
      type: call.isVideo ? 1 : 0,
      extra: {
        'callerId': call.remoteUserId.toString(),
        'userName': call.remoteName,
        'isVideo': call.isVideo.toString(),
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'videoChat',
        audioSessionActive: true,
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
    debugPrint('[QB] Showing outgoing CallKit for ${call.sessionId}');
  }

  // ─────────────────────────────────────────────────────────────────
  // Call Timeout
  // ─────────────────────────────────────────────────────────────────

  void _startCallTimeout(String sessionId) {
    _cancelCallTimeout();

    _callTimeoutTimer = Timer(kCallTimeout, () async {
      debugPrint('[QB] Call timeout: $sessionId');

      if (_activeCall?.sessionId == sessionId) {
        if (_callState == CallState.incoming) {
          await rejectCall(sessionId);
        } else if (_callState == CallState.outgoing) {
          await hangUp(sessionId);
        }

        _callStateController.add({
          'type': 'timeout',
          'sessionId': sessionId,
        });
      }
    });
  }

  void _cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  // ─────────────────────────────────────────────────────────────────
  // Media Controls
  // ─────────────────────────────────────────────────────────────────

  Future<void> setAudioEnabled({
    required String sessionId,
    required bool enabled,
  }) async {
    try {
      await QB.webrtc.enableAudio(sessionId, enable: enabled);
      debugPrint('[QB] Audio ${enabled ? 'enabled' : 'muted'}');
    } catch (e) {
      debugPrint('[QB] Audio toggle error: $e');
    }
  }

  Future<void> setVideoEnabled({
    required String sessionId,
    required bool enabled,
  }) async {
    try {
      await QB.webrtc.enableVideo(sessionId, enable: enabled);
      debugPrint('[QB] Video ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('[QB] Video toggle error: $e');
    }
  }

  Future<void> switchCamera(String sessionId) async {
    try {
      await QB.webrtc.switchCamera(sessionId);
      debugPrint('[QB] Camera switched');
    } catch (e) {
      debugPrint('[QB] Switch camera error: $e');
    }
  }

  Future<void> switchAudioOutput(int output) async {
    try {
      await QB.webrtc.switchAudioOutput(output);
      debugPrint('[QB] Audio output switched to $output');
    } catch (e) {
      debugPrint('[QB] Switch audio error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────

  void _navigateToCallScreen(ActiveCall call) {
    // Use GetX navigation - adjust based on your routing setup
    if(call.isVideo){
      Get.to(
            () => VideoCallScreen(
          sessionId: call.sessionId,
          userName: call.remoteName,
          remoteId: call.remoteUserId,
          currentUserId: currentUserId ?? 0,
        ),
        preventDuplicates: true,
      );
    }else{
      Get.to(
            () => AudioCallScreen(
          sessionId: call.sessionId,
          userName: call.remoteName,
          remoteId: call.remoteUserId,
          currentUserId: currentUserId ?? 0,
        ),
        preventDuplicates: true,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────

  Future<void> _cleanupCall(String sessionId, String reason) async {
    debugPrint('[QB] Cleaning up call: $sessionId, reason: $reason');

    _cancelCallTimeout();

    try {
      await FlutterCallkitIncoming.endCall(sessionId);
    } catch (e) {
      debugPrint('[QB] End CallKit error: $e');
    }

    if (_activeCall?.sessionId == sessionId) {
      _setCallState(CallState.idle, null);
    }
  }

  Future<void> _endCurrentCall({String? reason}) async {
    final call = _activeCall;
    if (call == null) return;

    _cancelCallTimeout();

    try {
      if (_callState == CallState.connected ||
          _callState == CallState.connecting ||
          _callState == CallState.outgoing) {
        await QB.webrtc.hangUp(call.sessionId, userInfo: {});
      } else if (_callState == CallState.incoming) {
        await QB.webrtc.reject(call.sessionId, userInfo: {'reason': reason ?? 'ended'});
      }
    } catch (e) {
      debugPrint('[QB] End call error: $e');
    }

    await _cleanupCall(call.sessionId, reason ?? 'ended');
  }

  void _setCallState(CallState state, ActiveCall? call) {
    _callState = state;
    _activeCall = call;
    debugPrint('[QB] Call state: $state, activeCall: ${call?.sessionId}');
  }

  void _clearAllState() {
    currentUserId = null;
    _activeCall = null;
    _callState = CallState.idle;
    _isLoggedIn = false;
    _isConnecting = false;
    _connectionStateController.add(false);
  }

  // ─────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('[QB] App lifecycle: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_manualLogout) {
          final alive = await _isSessionAlive();
          if (!alive && _email != null && _password != null) {
            await login(email: _email!, password: _password!);
          }
        }
        break;

      case AppLifecycleState.paused:
      // App going to background - CallKit handles calls
        break;

      case AppLifecycleState.detached:
      // App being terminated
        break;

      default:
        break;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);

    _reconnectTimer?.cancel();
    _callTimeoutTimer?.cancel();

    await _endCurrentCall(reason: 'dispose');
    await QB.webrtc.release();

    await _incomingCallController.close();
    await _callStateController.close();
    await _connectionStateController.close();

    debugPrint('[QB] Service disposed');
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  String? _extractSessionId(dynamic data) {
    final payload = data?['payload'] ?? data;
    return payload?['session']?['id']?.toString() ??
        payload?['sessionId']?.toString();
  }

  int? _extractCallerId(dynamic data) {
    final payload = data?['payload'] ?? data;
    final raw = payload?['session']?['initiatorId'] ?? payload?['callerId'];
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse(raw.toString());
  }

  String? _extractUserName(dynamic data) {
    final payload = data?['payload'] ?? data;
    return payload?['userInfo']?['userName']?.toString();
  }

  bool _extractIsVideo(dynamic data) {
    final payload = data?['payload'] ?? data;
    final type = payload?['session']?['type'];
    return type == QBRTCSessionTypes.VIDEO || type == 1;
  }
}

