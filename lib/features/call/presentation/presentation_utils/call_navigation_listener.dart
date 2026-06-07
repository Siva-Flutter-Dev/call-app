import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../bloc/call/call_bloc.dart';
import '../bloc/call/call_state.dart';

import '../bloc/control/call_control_bloc.dart';
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';

class CallNavigationListener
    extends StatelessWidget {

  final Widget child;

  const CallNavigationListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return BlocListener<CallBloc, CallState>(
      listener: (
          context,
          state,
          ) {

        if (state is VideoCallStarted) {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => CallControlBloc(
                  repository: sl(),
                  sessionId:
                  state.call.sessionId,
                ),
                child: VideoCallScreen(
                  call: state.call,
                ),
              ),
            ),
          );
        }

        if (state is AudioCallStarted) {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => CallControlBloc(
                  repository: sl(),
                  sessionId:
                  state.call.sessionId,
                ),
                child: AudioCallScreen(
                  call: state.call,
                ),
              ),
            ),
          );
        }

        if (state is CallRejected ||
            state is CallEnded) {

          Navigator.of(context)
              .popUntil(
                (route) => route.isFirst,
          );
        }
      },
      child: child,
    );
  }
}