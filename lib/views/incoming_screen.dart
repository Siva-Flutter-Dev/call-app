import 'dart:async';

import 'package:app/views/video_call.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/quickblox_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String sessionId;
  final int remoteId;
  final String userName;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.sessionId,
    required this.remoteId,
    required this.userName,
    required this.isVideo,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  StreamSubscription? _callStateSub;

  @override
  void initState() {
    super.initState();

    _listenCallEvents();
  }

  void _listenCallEvents() {

    _callStateSub ??=
        QuickBloxService.instance.onCallState.listen(
              (event) {

            final type = event['type'];

            switch (type) {
              case 'accepted':
                Get.off(VideoCallScreen(
                  sessionId: widget.sessionId,
                  remoteId: widget.remoteId,
                  userName: widget.userName,
                  currentUserId:
                  QuickBloxService
                      .instance
                      .currentUserId ??
                      0,
                ));
                break;

              case 'hangup':
              case 'rejected':
              case 'not_answer':

                if (mounted) {
                  Get.back();
                }

                break;
            }
          },
        );
  }

  @override
  void dispose() {
    _callStateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Profile Image
            Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade900,
              ),
              child: const Icon(
                Icons.person,
                size: 70,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Name
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Call Type
            Text(
              widget.isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // Ringing Text
            Text(
              'Ringing...',
              style: TextStyle(
                color: Colors.green.shade400,
                fontSize: 15,
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 40,
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  // Reject
                  _CallButton(
                    color: Colors.red,
                    icon: Icons.call_end,
                    label: 'Decline',
                    onTap: () async {
                      await QuickBloxService.instance
                          .rejectCall(widget.sessionId);

                      Navigator.pop(context);
                    },
                  ),

                  // Accept
                  _CallButton(
                    color: Colors.green,
                    icon: Icons.call,
                    label: 'Accept',
                    onTap: () async {
                      await QuickBloxService.instance
                          .acceptCall(
                        sessionId: widget.sessionId,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}