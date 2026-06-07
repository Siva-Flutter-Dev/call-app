import 'dart:async';

import 'package:app/features/chat/domain/entities/chat_messages_enitity.dart';
import 'package:flutter/material.dart';
import 'package:quickblox_sdk/auth/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk/webrtc/constants.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import '../../../../core/constants/qb_constants.dart';
import '../../../../core/services/callkit_service.dart';
import '../../domain/entities/active_call_entity.dart';
import '../models/active_call_model.dart';

class QuickBloxDataSource {
  final CallKitService callKitService;

  QuickBloxDataSource(this.callKitService,);

  int? currentUserId;

  String? _email;
  String? _password;

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isConnecting = false;
  bool _manualLogout = false;

  Timer? _reconnectTimer;
  Timer? _callTimeoutTimer;

  final _connectionStateController = StreamController<bool>.broadcast();

  final _incomingController = StreamController<ActiveCall>.broadcast();

  final _messageController = StreamController<ChatMessage>.broadcast();

  final Map<int, String> _dialogs = {};

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  int get myUserId => currentUserId ?? 0;

  Stream<bool> get onConnectionChanged => _connectionStateController.stream;

  Stream<ActiveCall> get incomingCalls => _incomingController.stream;

  Stream<ChatMessage> get messages => _messageController.stream;

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> initialize() async {
    if (_initialized) return;

    await QB.settings.init(
      QBConstants.appId,
      QBConstants.authKey,
      QBConstants.authSecret,
      QBConstants.accountKey,
    );

    await QB.settings.enableLogging();
    await QB.settings.enableXMPPLogging();

    _initialized = true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_isConnecting) {
      debugPrint('[QB] Login already in progress');
      return false;
    }

    _isConnecting = true;
    _manualLogout = false;
    try {
      _email = email;
      _password = password;

      final result =
      await QB.auth.loginWithEmail(
        email,
        password,
      );

      currentUserId =
          result.qbUser?.id;

      if (currentUserId == null) {
        throw Exception('User ID is null after login');
      }

      final isConnected = await QB.chat.isConnected() ?? false;
      if (!isConnected) {
        await QB.chat.connect(currentUserId!, password);
      }

      await QB.webrtc.init();

      await _subscribeRtc();

      _listenSessionExpiry();

      _isLoggedIn = true;
      _connectionStateController.add(true);

      return true;
    } catch (e) {
      debugPrint(
        'QB Login Error => $e',
      );
      return false;
    } finally {
      _isConnecting = false;
    }
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
    _reconnectTimer = Timer.periodic(QBConstants.reconnectInterval, (_) async {
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

  Future<void> logout() async {
    _manualLogout = true;
    _reconnectTimer?.cancel();
    _callTimeoutTimer?.cancel();

    try {
      final isConnected = await QB.chat.isConnected() ?? false;
      if (isConnected) {
        await QB.chat.disconnect();
      }

      await QB.webrtc.release();
      await QB.auth.logout();
    } catch (e) {
      debugPrint('[QB] Logout error: $e');
    }
    debugPrint('[QB] Logged out');
  }

  Future<List<QBUser?>> getUsers() async {
    final result =
    await QB.users.getUsers();

    return result;
  }

  Future<String?> startCall({
    required List<int> opponents,
    required bool isVideo,
    required String userName,
  }) async {
    try {
      final session =
      await QB.webrtc.call(
        opponents,
        isVideo
            ? QBRTCSessionTypes.VIDEO
            : QBRTCSessionTypes.AUDIO,
        userInfo: {
          'userName': userName,
          'callerId':
          currentUserId.toString(),
        },
      );

      return session?.id;
    } catch (e) {
      debugPrint(
        'QB Call Error => $e',
      );

      return null;
    }
  }

  Future<void> acceptCall(
      String sessionId,
      ) async {
    await QB.webrtc.accept(
      sessionId,
      userInfo: {},
    );

    await callKitService
        .setConnected(
      sessionId,
    );
  }

  Future<void> rejectCall(
      String sessionId,
      ) async {
    await QB.webrtc.reject(
      sessionId,
      userInfo: {
        'reason': 'declined',
      },
    );

    await callKitService.endCall(
      sessionId,
    );
  }

  Future<void> hangUp(
      String sessionId,
      ) async {
    await QB.webrtc.hangUp(
      sessionId,
      userInfo: {},
    );

    await callKitService.endCall(
      sessionId,
    );
  }

  Future<void> muteAudio({
    required String sessionId,
    required bool enable,
  }) async {
    await QB.webrtc.enableAudio(
      sessionId,
      enable: enable,
    );
  }

  Future<void> enableVideo({
    required String sessionId,
    required bool enable,
  }) async {
    await QB.webrtc.enableVideo(
      sessionId,
      enable: enable,
    );
  }

  Future<void> switchCamera(
      String sessionId,
      ) async {
    await QB.webrtc.switchCamera(
      sessionId,
    );
  }

  Future<String> getPrivateDialogId(
      int opponentId,
      ) async {
    if (_dialogs.containsKey(
      opponentId,
    )) {
      return _dialogs[opponentId]!;
    }

    try {
      final dialogs = await QB.chat.getDialogs();

      for (final dialog in dialogs) {
        if (dialog == null) continue;

        final occupants =
            dialog.occupantsIds ?? [];

        if (occupants.contains(
          opponentId,
        ) &&
            occupants.length == 2) {
          _dialogs[opponentId] =
          dialog.id!;

          return dialog.id!;
        }
      }

      final QBDialog? dialog =
      await QB.chat.createDialog(
        QBChatDialogTypes.CHAT,
        occupantsIds: [
          opponentId,
        ],
        dialogName:
        'private_$opponentId',
      );

      _dialogs[opponentId] =
      dialog!.id!;

      return dialog.id!;
    } catch (e) {
      debugPrint(
        "DIALOG ERROR => $e",
      );

      rethrow;
    }
  }

  Future<void> sendMessage({
    required int opponentId,
    required String text,
  }) async {
    try {
      final dialogId =
      await getPrivateDialogId(
        opponentId,
      );

      await QB.chat.sendMessage(
        dialogId,
        body: text,
        saveToHistory: true,
      );
    } catch (e) {
      debugPrint(
        "SEND MESSAGE ERROR => $e",
      );
    }
  }

  Future<List<ChatMessage>> getMessages(
      int opponentId,
      ) async {
    final dialogId =
    await getPrivateDialogId(
      opponentId,
    );

    final result =
    await QB.chat.getDialogMessages(
      dialogId,
      markAsRead: true,
    );

    return result
        .whereType<QBMessage>()
        .map(
          (e) => ChatMessage(
        id: e.id ?? '',
        senderId:
        e.senderId ?? 0,
        receiverId:
        e.recipientId ?? 0,
        message:
        e.body ?? '',
        createdAt:
        DateTime.now(),
      ),
    )
        .toList();
  }

  Future<void> _subscribeRtc() async {
    await QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.CALL,
      _onIncomingCall,
    );

    await QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.ACCEPT,
      _onAccept,
    );

    await QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.REJECT,
      _onReject,
    );

    await QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.HANG_UP,
      _onHangup,
    );

    await QB.webrtc.subscribeRTCEvent(
      QBRTCEventTypes.NOT_ANSWER,
      _onNoAnswer,
    );

    await QB.chat.subscribeChatEvent(
      QBChatEvents.RECEIVED_NEW_MESSAGE,
          _onMessage,
    );
  }

  void _onIncomingCall(
      dynamic data,
      ) async {
    final payload =
    data['payload'];

    final session =
    payload['session'];

    final sessionId =
    session['id'].toString();

    final callerId =
    session['initiatorId'];

    final userName =
        payload['userInfo']
        ?['userName'] ??
            'Unknown';

    final isVideo =
        session['type'] ==
            QBRTCSessionTypes.VIDEO;

    final call =
    ActiveCallModel(
      sessionId: sessionId,
      remoteUserId: callerId,
      remoteName: userName,
      isVideo: isVideo,
      direction:
      CallDirection.incoming,
    );

    await callKitService
        .showIncomingCall(
      call,
    );

    _incomingController.add(
      call,
    );
  }

  void _onAccept(dynamic data,) {
    _eventController.add({
      'type': 'accepted',
      'payload': data,
    });
  }

  Future<void> _onReject(dynamic data) async {
    try {
      final payload =
      Map<String, dynamic>.from(
        data['payload'],
      );

      final session =
      Map<String, dynamic>.from(
        payload['session'],
      );

      final sessionId =
      session['id'].toString();

      await callKitService.endCall(
        sessionId,
      );

      _eventController.add({
        'type': 'rejected',
        'payload': data,
      });
    } catch (e) {
      debugPrint(
        'REJECT ERROR => $e',
      );
    }
  }

  Future<void> _onHangup(dynamic data,) async {
    try {
      final payload =
      Map<String, dynamic>.from(
        data['payload'],
      );

      final session =
      Map<String, dynamic>.from(
        payload['session'],
      );

      final sessionId =
      session['id'].toString();

      await callKitService.endCall(
        sessionId,
      );

      _eventController.add({
        'type': 'hangup',
        'payload': data,
      });
    } catch (e) {
      debugPrint(
        'HANGUP ERROR => $e',
      );
    }
  }

  Future<void> _onNoAnswer(dynamic data,) async {
    try {
      final payload =
      Map<String, dynamic>.from(
        data['payload'],
      );

      final session =
      Map<String, dynamic>.from(
        payload['session'],
      );

      final sessionId =
      session['id'].toString();

      await callKitService.endCall(
        sessionId,
      );

      _eventController.add({
        'type': 'no_answer',
        'payload': data,
      });
    } catch (e) {
      debugPrint(
        'NO ANSWER ERROR => $e',
      );
    }
  }

  void _onMessage(dynamic data) {
    try {
      final payload =
      Map<String, dynamic>.from(
        data["payload"],
      );

      final message =
      ChatMessage(
        id: payload['id']?.toString() ?? '',
        senderId: payload['senderId'] ?? 0,
        receiverId: payload['recipientId'] ?? 0,
        message: payload['body'] ?? '',
        createdAt: DateTime.now(),
      );

      _messageController.add(
        message,
      );
    } catch (e) {
      debugPrint(
        "MESSAGE EVENT ERROR => $e",
      );
    }
  }

  Future<void> dispose() async {
    await _incomingController.close();

    await _eventController.close();

    await _messageController.close();
  }
}