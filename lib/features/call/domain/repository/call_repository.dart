import 'package:app/features/chat/domain/entities/chat_messages_enitity.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/models/qb_user.dart';

import '../entities/active_call_entity.dart';

abstract class CallRepository {

  Future<bool> login({required String email, required String password});

  Future<void> logout();

  Future<String?> startCall({required List<int> opponents, required bool isVideo, required String userName});

  Future<void> acceptCall(String sessionId);

  Future<void> rejectCall(String sessionId);

  Future<void> hangup(String sessionId);

  Future<void> mute(String sessionId, bool enabled);

  Future<void> video(String sessionId, bool enabled);

  Future<void> switchCamera(String sessionId);

  Stream<ActiveCall> incomingCalls();

  Future<List<QBUser?>> getUsers();

  Future<void> sendMessage({required int opponentId, required String text,});

  Future<List<ChatMessage?>> getMessages(int opponentId,);

  Stream<ChatMessage> chatMessages();

  Stream<Map<String,dynamic>> callEvents();
}