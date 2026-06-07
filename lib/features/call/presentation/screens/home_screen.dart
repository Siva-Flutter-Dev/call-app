import 'package:app/features/call/presentation/presentation_utils/call_navigation_listener.dart';
import 'package:app/features/call/presentation/screens/audio_call_screen.dart';
import 'package:app/features/call/presentation/screens/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../chat/domain/entities/chat_entity.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/bloc/chat_events.dart';
import '../../../chat/presentation/bloc/chat_states.dart';
import '../../../chat/presentation/screens/chat_conversation_screen.dart';
import '../../domain/entities/active_call_entity.dart';
import '../bloc/call/call_events.dart';

import '../../../call/presentation/bloc/call/call_bloc.dart';
import '../bloc/control/call_control_bloc.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    context.read<ChatBloc>().add(
      LoadUsers(),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return CallNavigationListener(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'QuickBlox Users',
          ),
        ),
        body: BlocBuilder<
            ChatBloc,
            ChatState>(
          builder:
              (context, state) {

            if (state is ChatLoading) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            if (state is ChatError) {
              return Center(
                child: Text(
                  state.message,
                ),
              );
            }

            if (state is UsersLoaded) {

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ChatBloc>()
                      .add(
                    LoadUsers(),
                  );
                },
                child:
                ListView.builder(
                  itemCount:
                  state.users.length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {

                    final user =
                    state.users[index];

                    return _userTile(
                      user,
                    );
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _userTile(
      ChatUser user,
      ) {
    return Card(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user.name
                .substring(0, 1)
                .toUpperCase(),
          ),
        ),

        title: Text(
          user.name,
        ),

        subtitle: Text(
          user.email ?? '',
        ),

        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [

            IconButton(
              icon:
              const Icon(
                Icons.chat,
              ),
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(
                          user: user,
                        ),
                  ),
                );
              },
            ),

            IconButton(
              icon:
              const Icon(
                Icons.call,
              ),
              onPressed: () {

                context
                    .read<
                    CallBloc>()
                    .add(
                  StartOutgoingCall(
                    opponents: [
                      user.id,
                    ],
                    isVideo: false,
                    userName:
                    user.name,
                  ),
                );
                final call = ActiveCall(
                  sessionId: '',
                  remoteUserId: user.id,
                  remoteName: user.name,
                  isVideo: false,
                  direction: CallDirection.outgoing,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => CallControlBloc(
                        repository: sl(),
                        sessionId: call.sessionId,
                      ),
                      child: AudioCallScreen(
                        call: call,
                      ),
                    ),
                  ),
                );
              },
            ),

            IconButton(
              icon:
              const Icon(
                Icons.videocam,
              ),
              onPressed: () {

                context.read<CallBloc>().add(
                  StartOutgoingCall(
                    opponents: [
                      user.id,
                    ],
                    isVideo: true,
                    userName:
                    user.name,
                  ),
                );

                final call = ActiveCall(
                  sessionId: '',
                  remoteUserId: user.id,
                  remoteName: user.name,
                  isVideo: false,
                  direction: CallDirection.outgoing,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => CallControlBloc(
                        repository: sl(),
                        sessionId: call.sessionId,
                      ),
                      child: VideoCallScreen(
                        call: call,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}