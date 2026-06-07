import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/active_call_entity.dart';
import '../bloc/call/call_bloc.dart';
import '../bloc/call/call_events.dart';
import '../bloc/control/call_control_bloc.dart';
import '../bloc/control/call_control_event.dart';
import '../bloc/control/call_controll_state.dart';
import '../widgets/call_actions.dart';

import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final ActiveCall call;

  const AudioCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  Timer? timer;

  int seconds = 0;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          setState(() {
            seconds++;
          });
        }
      },
    );
  }

  String get durationText {
    final m =
    (seconds ~/ 60).toString().padLeft(2, '0');

    final s =
    (seconds % 60).toString().padLeft(2, '0');

    return '$m:$s';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<
          CallControlBloc,
          CallControlState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                const Spacer(),

                CircleAvatar(
                  radius: 70,
                  child: Text(
                    widget.call.remoteName
                        .substring(0, 1)
                        .toUpperCase(),
                    style:
                    const TextStyle(
                      fontSize: 40,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Text(
                  widget.call.remoteName,
                  style:
                  const TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  durationText,
                ),

                const Spacer(),

                Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 40,
                  ),
                  child: CallActions(
                    muted: state.muted,
                    speaker:
                    state.speakerEnabled,
                    videoEnabled:
                    false,
                    onMute: () {
                      context
                          .read<
                          CallControlBloc>()
                          .add(
                        ToggleMute(),
                      );
                    },
                    onSpeaker: () {
                      context
                          .read<
                          CallControlBloc>()
                          .add(
                        ToggleSpeaker(),
                      );
                    },
                    onVideo: () {},
                    onSwitchCamera: () {},
                    onHangup: () {
                      context
                          .read<CallBloc>()
                          .add(
                        HangupRequested(
                          widget.call
                              .sessionId,
                        ),
                      );

                      Navigator.pop(
                        context,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}