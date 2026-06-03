import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickblox_sdk/webrtc/rtc_video_view.dart';

import '../services/quickblox_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String sessionId;
  final String userName;
  final int remoteId;
  final int currentUserId;

  const VideoCallScreen({
    super.key,
    required this.sessionId,
    required this.userName,
    required this.remoteId,
    required this.currentUserId,
  });

  @override
  State<VideoCallScreen> createState() =>
      _VideoCallScreenState();
}

class _VideoCallScreenState
    extends State<VideoCallScreen>
    with WidgetsBindingObserver {

  RTCVideoViewController?
  _localController;

  RTCVideoViewController?
  _remoteController;

  StreamSubscription?
  _callStateSubscription;

  Timer? _callTimer;

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isConnected = false;

  bool _localRendered = false;
  bool _remoteRendered = false;

  Duration _callDuration =
      Duration.zero;

  final QuickBloxService _service =
      QuickBloxService.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _listenCallEvents();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    if (state ==
        AppLifecycleState.detached) {

      _safeEndCall();
    }
  }

  void _listenCallEvents() {

    _callStateSubscription ??=
        _service.onCallState.listen(
              (event) {

            final type =
            event['type'];

            print("type--->$type");

            switch (type) {
              case 'rejected':
              case 'hangup':
              case 'not_answer':

                _closeScreen();

                break;
              case 'video_track':

                _playRemoteVideo();
                break;
            }
          },
        );
  }

  void _onLocalCreated(
      RTCVideoViewController
      controller,
      ) {

    _localController = controller;

    _playLocalVideo();
  }

  void _onRemoteCreated(
      RTCVideoViewController
      controller,
      ) {

    _remoteController = controller;
  }

  Future<void> _playLocalVideo() async {

    if (_localRendered ||
        _localController == null) {
      return;
    }

    try {

      _localRendered = true;

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      await _localController!.play(
        widget.sessionId,
        widget.currentUserId,
      );

      await _localController!.setMirror(true);

    } catch (e) {

      debugPrint(
        "LOCAL VIDEO ERROR => $e",
      );
    }
  }

  Future<void> _playRemoteVideo() async {

    if (_remoteController == null) {
      return;
    }

    try {

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      await _remoteController!.play(
        widget.sessionId,
        widget.remoteId,
      );

      if(mounted) setState(() {});

    } catch (e) {

      debugPrint(
        "REMOTE VIDEO ERROR => $e",
      );
    }
  }

  void _validateConnection() {

    if (_isConnected) return;

    _isConnected = true;
    setState(() {});
    _startCallTimer();
  }

  void _startCallTimer() {

    _callTimer?.cancel();

    _callTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {

        if (!mounted) return;

        setState(() {
          _callDuration +=
          const Duration(
            seconds: 1,
          );
        });
      },
    );
    setState(() {});
  }

  String _formatDuration() {

    String twoDigits(int n) =>
        n.toString().padLeft(2, '0');

    final hours = twoDigits(
      _callDuration.inHours,
    );

    final minutes = twoDigits(
      _callDuration.inMinutes
          .remainder(60),
    );

    final seconds = twoDigits(
      _callDuration.inSeconds
          .remainder(60),
    );

    if (_callDuration.inHours >
        0) {
      return "$hours:$minutes:$seconds";
    }

    return "$minutes:$seconds";
  }

  Future<void> _toggleMute()
  async {

    _isMuted = !_isMuted;

    setState(() {});

    await _service
        .setAudioEnabled(
      sessionId:
      widget.sessionId,
      enabled: !_isMuted,
    );
  }

  Future<void>
  _toggleVideo() async {

    _isVideoEnabled =
    !_isVideoEnabled;

    setState(() {});

    await _service
        .setVideoEnabled(
      sessionId:
      widget.sessionId,
      enabled:
      _isVideoEnabled,
    );
  }

  // Future<void>
  // _switchCamera() async {
  //
  //   await _service.switchCamera(
  //     widget.sessionId,
  //   );
  // }

  Future<void>
  _safeEndCall() async {

    try {

      await _service.hangUp(
        widget.sessionId,
      );

    } catch (_) {}
  }

  Future<void> _endCall() async {

    await _safeEndCall();

    _closeScreen();
  }

  void _closeScreen() {

    if (!mounted) return;

    Get.back();
  }

  Widget _remoteVideoView() {

    return RTCVideoView(
      key: const ValueKey(
        "remote_video",
      ),

      onVideoViewCreated:
      _onRemoteCreated,
    );
  }

  Widget _localVideoView() {

    return RTCVideoView(
      key: const ValueKey(
        "local_video",
      ),

      onVideoViewCreated:
      _onLocalCreated,
    );
  }

  Widget _topSection() {

    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,

      child: SafeArea(
        child: Column(
          children: [

            Hero(
              tag:
              widget.userName,

              child: Material(
                color:
                Colors.transparent,

                child: Text(
                  widget.userName,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    28,
                    fontWeight:
                    FontWeight
                        .w700,
                    letterSpacing:
                    0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            AnimatedContainer(
              duration:
              const Duration(
                milliseconds:
                300,
              ),

              padding:
              const EdgeInsets.symmetric(
                horizontal:
                18,
                vertical: 8,
              ),

              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  30,
                ),

                color: Colors.black
                    .withValues(
                  alpha:
                  0.28,
                ),

                border: Border.all(
                  color: Colors.white
                      .withValues(
                    alpha:
                    0.15,
                  ),
                ),
              ),

              child: Text(
                _isConnected
                    ? _formatDuration()
                    : "Connecting...",

                style:
                TextStyle(
                  color: Colors
                      .white
                      .withValues(
                    alpha:
                    0.95,
                  ),
                  fontSize:
                  14,
                  fontWeight:
                  FontWeight
                      .w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _localPreview() {

    return Positioned(
      top: 120,
      right: 20,

      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(
          10,
        ),

        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),

          child: Container(
            width: 120,
            height: 180,
            padding: const EdgeInsets.all(2),
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                10,
              ),

              border: Border.all(
                color: Colors.white
                    .withValues(
                  alpha:
                  0.15,
                ),
              ),

              color: Colors.white,
            ),

            child:
            _localVideoView(),
          ),
        ),
      ),
    );
  }

  Widget _controls() {

    return Positioned(
      bottom: 45,
      left: 0,
      right: 0,

      child: SafeArea(
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceEvenly,

          children: [

            _controlButton(
              icon: _isMuted
                  ? Icons.mic_off
                  : Icons.mic,

              onTap:
              _toggleMute,
            ),

            _controlButton(
              icon:
              Icons.call_end,

              isEnd: true,

              onTap:
              _endCall,
            ),

            _controlButton(
              icon:
              _isVideoEnabled
                  ? Icons
                  .videocam
                  : Icons
                  .videocam_off,

              onTap:
              _toggleVideo,
            ),

            // _controlButton(
            //   icon: Icons
            //       .flip_camera_ios,
            //
            //   onTap:
            //   _switchCamera,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isEnd = false,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 220,
        ),

        width: isEnd ? 90 : 64,
        height: isEnd ? 90 : 64,

        decoration:
        BoxDecoration(
          shape: BoxShape.circle,

          gradient: isEnd
              ? const LinearGradient(
            colors: [
              Color(
                0xFFFF4B4B,
              ),
              Color(
                0xFFFF1E1E,
              ),
            ],
          )
              : LinearGradient(
            colors: [
              Colors.white
                  .withValues(
                alpha:
                0.18,
              ),
              Colors.white
                  .withValues(
                alpha:
                0.08,
              ),
            ],
          ),

          border: Border.all(
            color: Colors.white
                .withValues(
              alpha: 0.15,
            ),
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: 1,
              color: isEnd
                  ? Colors.red
                  .withValues(
                alpha:
                0.4,
              )
                  : Colors.black
                  .withValues(
                alpha:
                0.18,
              ),
            ),
          ],
        ),

        child: Icon(
          icon,
          color: Colors.white,
          size: isEnd ? 34 : 30,
        ),
      ),
    );
  }

  Widget _blurOverlay() {

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 10,
        sigmaY: 10,
      ),

      child: Container(
        color: Colors.black
            .withValues(
          alpha: 0.1,
        ),
      ),
    );
  }

  @override
  void dispose() {

    WidgetsBinding.instance
        .removeObserver(this);

    _callTimer?.cancel();

    _callStateSubscription
        ?.cancel();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      backgroundColor:
      Colors.black,

      body: Stack(
        fit: StackFit.expand,

        children: [

          /// REMOTE VIDEO
          _remoteVideoView(),

          /// BLUR
          _blurOverlay(),

          /// TOP INFO
          _topSection(),

          /// LOCAL PREVIEW
          _localPreview(),

          /// CONTROLS
          _controls(),
        ],
      ),
    );
  }
}