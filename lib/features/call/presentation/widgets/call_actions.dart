import 'package:flutter/material.dart';

class CallActions extends StatelessWidget {
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onVideo;
  final VoidCallback onSwitchCamera;
  final VoidCallback onHangup;

  final bool muted;
  final bool speaker;
  final bool videoEnabled;

  const CallActions({
    super.key,
    required this.onMute,
    required this.onSpeaker,
    required this.onVideo,
    required this.onSwitchCamera,
    required this.onHangup,
    required this.muted,
    required this.speaker,
    required this.videoEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: onMute,
          icon: Icon(
            muted
                ? Icons.mic_off
                : Icons.mic,
          ),
        ),

        IconButton(
          onPressed: onSpeaker,
          icon: Icon(
            speaker
                ? Icons.volume_up
                : Icons.hearing,
          ),
        ),

        IconButton(
          onPressed: onVideo,
          icon: Icon(
            videoEnabled
                ? Icons.videocam
                : Icons.videocam_off,
          ),
        ),

        IconButton(
          onPressed: onSwitchCamera,
          icon: const Icon(
            Icons.flip_camera_ios,
          ),
        ),

        CircleAvatar(
          radius: 30,
          child: IconButton(
            onPressed: onHangup,
            icon: const Icon(
              Icons.call_end,
            ),
          ),
        ),
      ],
    );
  }
}