import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_messages_enitity.dart';
import '../../domain/repository/chat_repository.dart';
import 'chat_events.dart';
import 'chat_states.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  StreamSubscription? _messageSub;

  final List<ChatMessage> _messages = [];

  ChatBloc({
    required this.repository,
  }) : super(ChatInitial()) {
    on<LoadUsers>(_loadUsers);

    on<LoadMessages>(_loadMessages);

    on<SendMessage>(_sendMessage);

    on<MessageReceived>(_messageReceived);

    _listenMessages();
  }

  void _listenMessages() {
    _messageSub =
        repository.messages().listen(
              (message) {
            add(
              MessageReceived(
                message,
              ),
            );
          },
        );
  }

  Future<void> _loadUsers(
      LoadUsers event,
      Emitter<ChatState> emit,
      ) async {
    emit(ChatLoading());

    try {
      final users =
      await repository.getUsers();

      emit(
        UsersLoaded(
          users,
        ),
      );
    } catch (e) {
      emit(
        ChatError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> _loadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    try {
      final messages =
      await repository.getMessages(
        event.userId,
      );

      _messages
        ..clear()
        ..addAll(messages);

      emit(
        MessagesLoaded(
          List.from(_messages),
        ),
      );
    } catch (e) {
      emit(
        ChatError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> _sendMessage(
      SendMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await repository.sendMessage(
        userId: event.userId,
        message: event.message,
      );
    } catch (e) {
      emit(
        ChatError(
          e.toString(),
        ),
      );
    }
  }

  void _messageReceived(
      MessageReceived event,
      Emitter<ChatState> emit,
      ) {
    _messages.add(
      event.message,
    );

    emit(
      MessagesLoaded(
        List.from(_messages),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _messageSub?.cancel();
    return super.close();
  }
}