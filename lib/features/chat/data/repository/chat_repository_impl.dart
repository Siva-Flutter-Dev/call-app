import 'package:app/features/chat/domain/entities/chat_messages_enitity.dart';

import '../../../call/data/datasource/quickbox_datasource.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repository/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {

  final QuickBloxDataSource datasource;

  ChatRepositoryImpl(
      this.datasource,
      );

  @override
  Future<List<ChatUser>> getUsers()
  async {
    final users =
    await datasource.getUsers();

    return users
        .where(
          (e) =>
      e?.id !=
          datasource.currentUserId,
    )
        .map(
          (e) => ChatUser(
        id: e!.id!,
        name:
        e.fullName ??
            e.login ??
            '',
        email: e.email,
      ),
    )
        .toList();
  }

  @override
  Future<void> sendMessage({
    required int userId,
    required String message,
  }) {
    return datasource.sendMessage(
      opponentId: userId, text: message,
    );
  }

  @override
  Future<List<ChatMessage>> getMessages(int userId) {
    return datasource.getMessages(userId);
  }

  @override
  Stream<ChatMessage> messages() {
    return datasource.messages;
  }
}