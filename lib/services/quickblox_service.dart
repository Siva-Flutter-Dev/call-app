import 'dart:async';
import 'package:app/views/video_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickblox_sdk/auth/constants.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/webrtc/constants.dart';

class QuickBloxService with WidgetsBindingObserver {
  QuickBloxService._();

  static final QuickBloxService instance = QuickBloxService._();

  int? currentUserId;

  String? _email;
  String? _password;

  String? activeSessionId;
  int? remoteUserId;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isConnecting = false;
  bool _manualLogout = false;
  bool _rtcSubscribed = false;
  bool _callkitInitialized = false;

  Timer? _reconnectTimer;

  final StreamController<Map<String, dynamic>> _incomingCallController = StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _callStateController = StreamController.broadcast();

  final StreamController<bool> _connectionStateController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get onIncomingCall => _incomingCallController.stream;

  Stream<Map<String, dynamic>> get onCallState => _callStateController.stream;

  Stream<bool> get onConnectionChanged => _connectionStateController.stream;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);

      await _requestPermissions();

      await QB.settings.init(
        appId,
        authKey,
        authSecret,
        accountKey,
      );

      await QB.settings.enableLogging();
      await QB.settings.enableXMPPLogging();

      await _initializeCallKit();

      await _subscribeRTCEvents();

      _isInitialized = true;

      debugPrint('QuickBlox Initialized');
    } on PlatformException catch (e) {
      debugPrint('QB Init Error => ${e.message}');
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    _manualLogout = false;

    try {
      _email = email;
      _password = password;

      final QBLoginResult result =
      await QB.auth.loginWithEmail(email, password);

      currentUserId = result.qbUser?.id;

      if (currentUserId == null) {
        throw Exception('User ID is null');
      }

      final connected = await QB.chat.isConnected();

      if (connected==false) {
        await QB.chat.connect(currentUserId!, password);
      }

      await QB.webrtc.init();

      _listenSessionExpiry();

      _isLoggedIn = true;

      _connectionStateController.add(true);

      debugPrint('QB Login Success => $currentUserId');

      return true;
    } catch (e) {
      debugPrint('QB Login Error => $e');

      _startReconnect();

      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> logout() async {
    _manualLogout = true;

    try {
      _reconnectTimer?.cancel();

      await endAllCalls();

      final connected = await QB.chat.isConnected();

      if (connected==true) {
        await QB.chat.disconnect();
      }

      await QB.auth.logout();
    } catch (e) {
      debugPrint('Logout Error => $e');
    }

    _clearAllState();
  }

  Future<String?> startCall({
    required List<int> opponentIds,
    required String userName,
    bool isVideo = true,
  }) async {
    try {
      await QB.webrtc.init();
      final session = await QB.webrtc.call(
        opponentIds,
        isVideo
            ? QBRTCSessionTypes.VIDEO
            : QBRTCSessionTypes.AUDIO,
        userInfo: {
          'userName': userName,
        },
      );

      activeSessionId = session?.id;
      remoteUserId = opponentIds.first;

      if (activeSessionId != null) {
        // await _startOutgoingCallKit(
        //   sessionId: activeSessionId!,
        //   userName: userName,
        //   userId: remoteUserId.toString(),
        //   isVideo: isVideo,
        // );
        Get.to(VideoCallScreen(
            sessionId: activeSessionId!,
            userName: userName,
            remoteId: remoteUserId??0,
            currentUserId: currentUserId??0));
      }

      debugPrint('Call Started => $activeSessionId');

      return activeSessionId;
    } catch (e) {
      debugPrint('Start Call Error => $e');
      return null;
    }
  }

  Future<void> acceptCall({
    required String sessionId,
  }) async {
    try {
      await QB.webrtc.accept(sessionId, userInfo: {});

      activeSessionId = sessionId;

      await FlutterCallkitIncoming.setCallConnected(sessionId);

      _callStateController.add({
        'type': 'accepted',
        'sessionId': sessionId,
      });

      debugPrint('Call Accepted');
    } catch (e) {
      debugPrint('Accept Call Error => $e');
    }
  }

  Future<void> rejectCall(String sessionId) async {
    try {
      await QB.webrtc.reject(sessionId, userInfo: {});

      await FlutterCallkitIncoming.endCall(sessionId);

      clearCallState();

      _callStateController.add({
        'type': 'rejected',
        'sessionId': sessionId,
      });

      debugPrint('Call Rejected');
    } catch (e) {
      debugPrint('Reject Call Error => $e');
    }
  }

  Future<void> hangUp(String sessionId) async {
    try {
      await QB.webrtc.hangUp(sessionId, userInfo: {});

      await FlutterCallkitIncoming.endCall(sessionId);

      clearCallState();

      _callStateController.add({
        'type': 'hangup',
        'sessionId': sessionId,
      });

      debugPrint('Call Ended');
    } catch (e) {
      debugPrint('Hangup Error => $e');
    }
  }

  Future<void> setAudioEnabled({required String sessionId, required bool enabled,}) async {
    try {
      await QB.webrtc.enableAudio(
        sessionId,
        enable: enabled,
      );
    } catch (e) {
      debugPrint('Audio Toggle Error => $e');
    }
  }

  Future<void> setVideoEnabled({required String sessionId, required bool enabled,}) async {
    try {
      await QB.webrtc.enableVideo(
        sessionId,
        enable: enabled,
      );
    } catch (e) {
      debugPrint('Video Toggle Error => $e');
    }
  }

  Future<void> switchCamera(String sessionId) async {
    try {
      await QB.webrtc.switchCamera(sessionId);
    } catch (e) {
      debugPrint('Switch Camera Error => $e');
    }
  }

  Future<void> switchAudioOutput(int output) async {
    try {
      await QB.webrtc.switchAudioOutput(output);
    } catch (e) {
      debugPrint('Switch Audio Error => $e');
    }
  }

  Future<void> _subscribeRTCEvents() async {
    if (_rtcSubscribed) return;

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.CALL,
          (data) async {
        final sessionId = _extractSessionId(data);
        final callerId = _extractCallerId(data);
        final userName = _extractUserName(data);

        if (sessionId == null || callerId == null) return;

        activeSessionId = sessionId;
        remoteUserId = callerId;

        await _showIncomingCallKit(
          sessionId: sessionId,
          callerName: userName ?? 'Calling',
          callerId: callerId.toString(),
        );

        _incomingCallController.add({
          'sessionId': sessionId,
          'callerId': callerId,
          'userName': userName,
        });

        debugPrint('Incoming Call => $sessionId');
      },
    );

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.ACCEPT,
          (data) {
        _callStateController.add({
          'type': 'accepted',
          'data': data,
        });
      },
    );

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.REJECT,
          (data) async {
        await endAllCalls();

        clearCallState();

        _callStateController.add({
          'type': 'rejected',
          'data': data,
        });
      },
    );

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.HANG_UP,
          (data) async {
        await endAllCalls();

        clearCallState();

        _callStateController.add({
          'type': 'hangup',
          'data': data,
        });
      },
    );

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.NOT_ANSWER,
          (data) async {
        await endAllCalls();

        clearCallState();

        _callStateController.add({
          'type': 'not_answer',
          'data': data,
        });
      },
    );

    QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.RECEIVED_VIDEO_TRACK,
          (data) {
        _callStateController.add({
          'type': 'video_track',
          'data': data,
        });
      },
    );

    _rtcSubscribed = true;
  }

  Future<void> _initializeCallKit() async {
    if (_callkitInitialized) return;

    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;

      final body = event.body;

      final sessionId = body['id'];

      switch (event.event) {
        case Event.actionCallAccept:
          if (sessionId != null) {
            await acceptCall(sessionId: sessionId);
          }
          break;

        // case Event.actionCallIncoming:
        //   if (sessionId != null) {
        //     await _showIncomingCallKit(
        //         sessionId: sessionId,
        //         callerName: '',
        //         callerId: ''
        //     );
        //   }
        //   break;

        case Event.actionCallDecline:
          if (sessionId != null) {
            await rejectCall(sessionId);
          }
          break;

        case Event.actionCallEnded:
          if (sessionId != null) {
            await hangUp(sessionId);
          }
          break;

        default:
          break;
      }
    });

    _callkitInitialized = true;
  }

  Future<void> _showIncomingCallKit({required String sessionId, required String callerName, required String callerId, bool isVideo = true,}) async {
    //await FlutterCallkitIncoming.endAllCalls();

    final params = CallKitParams(
      id: sessionId,
      nameCaller: callerName,
      appName: 'BotzUp',
      handle: callerId,
      type: isVideo ? 1 : 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: {
        'callerId': callerId,
        'userName': callerName,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> _startOutgoingCallKit({required String sessionId, required String userName, required String userId, bool isVideo = true,}) async {
    final params = CallKitParams(
      id: sessionId,
      nameCaller: userName,
      appName: 'BotzUp',
      handle: userId,
      type: isVideo ? 1 : 0,
      extra: {
        'callerId': userId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
      ),
      ios: const IOSParams(
        supportsVideo: true,
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  void _startReconnect() {
    if (_manualLogout) return;

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) async {
        try {
          final alive = await _isSessionAlive();

          if (alive) {
            _reconnectTimer?.cancel();
            return;
          }

          if (_email != null && _password != null) {
            await login(
              email: _email!,
              password: _password!,
            );
          }
        } catch (e) {
          debugPrint('Reconnect Error => $e');
        }
      },
    );
  }

  void _listenSessionExpiry() {
    QB.auth.subscribeAuthEvent(
      QBAuthEvents.SESSION_EXPIRED,
          (data) async {
        debugPrint('Session Expired');

        _isLoggedIn = false;

        _startReconnect();
      },
    );
  }

  Future<bool> _isSessionAlive() async {
    try {
      final QBSession? session = await QB.auth.getSession();

      if (session == null) return false;

      if (currentUserId != null &&
          session.userId != currentUserId) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_manualLogout) {
          final alive = await _isSessionAlive();

          if (!alive &&
              _email != null &&
              _password != null) {
            await login(
              email: _email!,
              password: _password!,
            );
          }
        }
        break;

      default:
        break;
    }
  }

  /// Helpers
  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  String? _extractSessionId(dynamic data) {
    final payload = data?['payload'] ?? data;

    return payload?['session']?['id']?.toString() ??
        payload?['sessionId']?.toString();
  }

  int? _extractCallerId(dynamic data) {
    final payload = data?['payload'] ?? data;

    final raw = payload?['session']?['initiatorId'] ??
        payload?['callerId'];

    if (raw == null) return null;

    return raw is int ? raw : int.tryParse(raw.toString());
  }

  String? _extractUserName(dynamic data) {
    final payload = data?['payload'] ?? data;

    return payload?['userInfo']?['userName'];
  }

  Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  void clearCallState() {
    activeSessionId = null;
    remoteUserId = null;
  }

  void _clearAllState() {
    currentUserId = null;

    activeSessionId = null;
    remoteUserId = null;

    _isLoggedIn = false;
    _isConnecting = false;

    _connectionStateController.add(false);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);

    _reconnectTimer?.cancel();

    await QB.webrtc.release();

    await endAllCalls();

    await _incomingCallController.close();
    await _callStateController.close();
    await _connectionStateController.close();
  }
}


const String appId = '108053';
const String authKey = 'ak_qTej96WZDn6eDGJ';
const String authSecret = 'as_MThb9ZJgj7f9V4e';
const String accountKey = 'ack_wSHemJsk1e1t1bJYBVbN';
