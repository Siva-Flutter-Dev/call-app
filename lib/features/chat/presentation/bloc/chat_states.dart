import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/chat_messages_enitity.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class UsersLoaded extends ChatState {
  final List<ChatUser> users;

  UsersLoaded(this.users);
}

class MessagesLoaded extends ChatState {
  final List<ChatMessage> messages;

  MessagesLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;

  ChatError(this.message);
}