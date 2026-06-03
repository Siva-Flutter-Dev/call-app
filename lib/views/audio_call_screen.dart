import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/quickblox_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String sessionId;
  final String userName;
  final int remoteId;
  final int currentUserId;

  const AudioCallScreen({
    super.key,
    required this.sessionId,
    required this.userName,
    required this.remoteId,
    required this.currentUserId,
  });

  @override
  State<AudioCallScreen> createState() =>
      _AudioCallScreenState();
}

class _AudioCallScreenState
    extends State<AudioCallScreen>
    with WidgetsBindingObserver {

  final QuickBloxService _service =
      QuickBloxService.instance;

  StreamSubscription? _callStateSub;
  Timer? _timer;

  bool _isMuted = false;
  bool _speakerEnabled = false;
  bool _isConnected = false;

  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _listenEvents();
  }

  void _listenEvents() {

    _callStateSub =
        _service.onCallState.listen((event) {

          final type = event['type'];

          switch (type) {

            case 'accepted':

              if (!_isConnected) {
                _isConnected = true;
                _startTimer();

                if (mounted) {
                  setState(() {});
                }
              }
              break;

            case 'rejected':
            case 'hangup':
            case 'not_answer':

              _close();
              break;
          }
        });
  }

  void _startTimer() {

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {

        if (!mounted) return;

        setState(() {
          _duration +=
          const Duration(seconds: 1);
        });
      },
    );
  }

  String _formattedTime() {

    String two(int n) =>
        n.toString().padLeft(2, '0');

    final minutes = two(
      _duration.inMinutes.remainder(60),
    );

    final seconds = two(
      _duration.inSeconds.remainder(60),
    );

    return '$minutes:$seconds';
  }

  Future<void> _toggleMute() async {

    _isMuted = !_isMuted;

    setState(() {});

    await _service.setAudioEnabled(
      sessionId: widget.sessionId,
      enabled: !_isMuted,
    );
  }

  Future<void> _toggleSpeaker() async {

    _speakerEnabled = !_speakerEnabled;

    setState(() {});

    await _service.switchAudioOutput(
      _speakerEnabled ? 1 : 0,
    );
  }

  Future<void> _endCall() async {

    try {
      await _service.hangUp(
        widget.sessionId,
      );
    } catch (_) {}

    _close();
  }

  void _close() {

    if (!mounted) return;

    Get.back();
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isEnd = false,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: isEnd ? 80 : 65,
        height: isEnd ? 80 : 65,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnd
              ? Colors.red
              : Colors.white.withValues(alpha: .15),
        ),

        child: Icon(
          icon,
          color: Colors.white,
          size: isEnd ? 36 : 30,
        ),
      ),
    );
  }

  @override
  void dispose() {

    WidgetsBinding.instance
        .removeObserver(this);

    _timer?.cancel();
    _callStateSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff1E1E1E),
              Color(0xff000000),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              const Spacer(),

              CircleAvatar(
                radius: 60,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0]
                      .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _isConnected
                    ? _formattedTime()
                    : 'Calling...',
                style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: .8),
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                children: [

                  _controlButton(
                    icon: _isMuted
                        ? Icons.mic_off
                        : Icons.mic,
                    onTap: _toggleMute,
                  ),

                  _controlButton(
                    icon: Icons.call_end,
                    isEnd: true,
                    onTap: _endCall,
                  ),

                  _controlButton(
                    icon: _speakerEnabled
                        ? Icons.volume_up
                        : Icons.hearing,
                    onTap: _toggleSpeaker,
                  ),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}