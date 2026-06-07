import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickblox_sdk/webrtc/rtc_video_view.dart';

import '../../domain/entities/active_call_entity.dart';
import '../bloc/call/call_bloc.dart';

import '../bloc/call/call_events.dart';
import '../bloc/control/call_control_bloc.dart';
import '../bloc/control/call_control_event.dart';

import '../bloc/control/call_controll_state.dart';
import '../widgets/call_actions.dart';

class VideoCallScreen extends StatefulWidget {
  final ActiveCall call;

  const VideoCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<VideoCallScreen> createState() =>
      _VideoCallScreenState();
}

class _VideoCallScreenState
    extends State<VideoCallScreen> {
  RTCVideoViewController? _localController;

  RTCVideoViewController? _remoteController;

  bool _localRendered = false;

  bool _remoteRendered = false;

  int seconds = 0;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  void _startTimer() {
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

  void _onLocalCreated(
      RTCVideoViewController controller,
      ) {
    _localController = controller;

    _playLocalVideo();
  }

  void _onRemoteCreated(
      RTCVideoViewController controller,
      ) {
    _remoteController = controller;

    _playRemoteVideo();
  }

  Future<void> _playLocalVideo() async {
    if (_localRendered ||
        _localController == null) {
      return;
    }

    try {
      _localRendered = true;

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      await _localController!.play(
        widget.call.sessionId,
        0,
      );

      await _localController!.setMirror(
        true,
      );
    } catch (e) {
      debugPrint(
        "LOCAL VIDEO ERROR => $e",
      );
    }
  }

  Future<void> _playRemoteVideo() async {
    if (_remoteRendered ||
        _remoteController == null) {
      return;
    }

    try {
      _remoteRendered = true;

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await _remoteController!.play(
        widget.call.sessionId,
        widget.call.remoteUserId,
      );
    } catch (e) {
      debugPrint(
        "REMOTE VIDEO ERROR => $e",
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();

    // _localController?.dispose();
    //
    // _remoteController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<
          CallControlBloc,
          CallControlState>(
        builder: (context, state) {
          return Stack(
            children: [
              _remoteVideo(),

              _localVideo(),

              _topInfo(),

              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: CallActions(
                  muted: state.muted,
                  speaker: state.speakerEnabled,
                  videoEnabled:
                  state.videoEnabled,
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
                  onVideo: () {
                    context
                        .read<
                        CallControlBloc>()
                        .add(
                      ToggleVideo(),
                    );
                  },
                  onSwitchCamera: () {
                    context
                        .read<
                        CallControlBloc>()
                        .add(
                      SwitchCameraRequested(),
                    );
                  },
                  onHangup: () {
                    context
                        .read<CallBloc>()
                        .add(
                      HangupRequested(
                        widget.call.sessionId,
                      ),
                    );

                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _remoteVideo() {
    return Positioned.fill(
      child: RTCVideoView(
        onVideoViewCreated:
        _onRemoteCreated,
      ),
    );
  }

  Widget _localVideo() {
    return Positioned(
      top: 100,
      right: 20,
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(20),
        child: SizedBox(
          width: 120,
          height: 180,
          child: RTCVideoView(
            onVideoViewCreated:
            _onLocalCreated,
          ),
        ),
      ),
    );
  }

  Widget _topInfo() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            widget.call.remoteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            durationText,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}