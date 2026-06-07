import '../entities/chat_entity.dart';
import '../entities/chat_messages_enitity.dart';

abstract class ChatRepository {
  Future<List<ChatUser>> getUsers();

  Future<List<ChatMessage>> getMessages(int userId);

  Future<void> sendMessage({
    required int userId,
    required String message,
  });

  Stream<ChatMessage> messages();
}