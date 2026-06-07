import '../../domain/entities/chat_messages_enitity.dart';

abstract class ChatEvent {}

class LoadUsers extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final int userId;

  LoadMessages(this.userId);
}

class SendMessage extends ChatEvent {
  final int userId;
  final String message;

  SendMessage({
    required this.userId,
    required this.message,
  });
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  MessageReceived(this.message);
}