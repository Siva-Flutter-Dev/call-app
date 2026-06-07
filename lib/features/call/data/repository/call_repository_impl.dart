import 'package:app/features/chat/domain/entities/chat_messages_enitity.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import '../../domain/entities/active_call_entity.dart';
import '../../domain/repository/call_repository.dart';
import '../datasource/quickbox_datasource.dart';

class CallRepositoryImpl implements CallRepository {
  final QuickBloxDataSource datasource;

  CallRepositoryImpl(
      this.datasource,
      );

  @override
  Future<bool> login({
    required String email,
    required String password,
  }) {
    return datasource.login(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() {
    return datasource.logout();
  }

  @override
  Future<String?> startCall({
    required List<int> opponents,
    required bool isVideo,
    required String userName,
  }) {
    return datasource.startCall(
      opponents: opponents,
      isVideo: isVideo,
      userName: userName,
    );
  }

  @override
  Future<void> acceptCall(
      String sessionId,
      ) {
    return datasource.acceptCall(
      sessionId,
    );
  }

  @override
  Future<void> rejectCall(
      String sessionId,
      ) {
    return datasource.rejectCall(
      sessionId,
    );
  }

  @override
  Future<void> hangup(
      String sessionId,
      ) {
    return datasource.hangUp(
      sessionId,
    );
  }

  @override
  Future<void> switchCamera(
      String sessionId,
      ) {
    return datasource.switchCamera(
      sessionId,
    );
  }

  @override
  Stream<ActiveCall> incomingCalls() {
    return datasource.incomingCalls;
  }

  @override
  Stream<Map<String, dynamic>>
  callEvents() {
    return datasource.events;
  }

  @override
  Future<void> video(String sessionId, bool enabled) {
    return datasource.enableVideo(
      sessionId: sessionId, enable: enabled,
    );
  }

  @override
  Future<void> mute(String sessionId, bool enabled) {
    return datasource.muteAudio(
      sessionId: sessionId,
      enable: enabled,
    );
  }

  @override
  Future<List<QBUser?>> getUsers() {
    return datasource.getUsers();
  }

  @override
  Future<void> sendMessage({
    required int opponentId,
    required String text,
  }) {
    return datasource.sendMessage(
      opponentId: opponentId,
      text: text,
    );
  }

  @override
  Future<List<ChatMessage?>> getMessages(
      int opponentId,
      ) {
    return datasource.getMessages(
      opponentId,
    );
  }

  @override
  Stream<ChatMessage> chatMessages() {
    return datasource.messages;
  }
}