import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_events.dart';
import '../bloc/chat_states.dart';

class ChatScreen
    extends StatefulWidget {

  final ChatUser user;

  const ChatScreen({
    super.key,
    required this.user,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {

  final controller =
  TextEditingController();

  @override
  Widget build(
      BuildContext context,
      ) {

    return Scaffold(
      appBar: AppBar(
        title:
        Text(
          widget.user.name,
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child:
            BlocBuilder<
                ChatBloc,
                ChatState>(
              builder:
                  (context, state) {

                if (state
                is MessagesLoaded) {

                  return ListView.builder(
                    itemCount:
                    state.messages
                        .length,
                    itemBuilder:
                        (
                        context,
                        index,
                        ) {

                      final msg =
                      state.messages[
                      index];

                      return ListTile(
                        title:
                        Text(
                          msg.message,
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          Row(
            children: [

              Expanded(
                child:
                TextField(
                  controller:
                  controller,
                ),
              ),

              IconButton(
                icon:
                const Icon(
                  Icons.send,
                ),
                onPressed: () {

                  context
                      .read<
                      ChatBloc>()
                      .add(
                    SendMessage(
                      userId: widget.user.id,
                      message: controller.text,
                    ),
                  );

                  controller.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}