import 'package:flutter/material.dart';

import '../services/quickblox_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() =>
      _HomeState();
}

class _HomeState extends State<Home> {

  final QuickBloxService _qbService =
      QuickBloxService.instance;

  bool _isCalling = false;

  Future<void> _startCall({
    required int userId,
    required String userName,
  }) async {

    if (_isCalling) return;

    setState(() {
      _isCalling = true;
    });

    try {

      await _qbService.startCall(
        opponentIds: [userId],
        userName: userName,
        isVideo: false
      );

    } catch (e) {

      debugPrint(
        "START CALL ERROR => $e",
      );

    } finally {

      if (mounted) {

        setState(() {
          _isCalling = false;
        });
      }
    }
  }

  Widget _callCard({
    required String title,
    required String subtitle,
    required int userId,
    required IconData icon,
  }) {

    final bool isCurrentUser =
        _qbService.currentUserId ==
            userId;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),

      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(24),

        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),

        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.08,
          ),
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: 1,
            offset:
            const Offset(0, 8),
            color: Colors.black
                .withValues(
              alpha: 0.18,
            ),
          ),
        ],
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Row(
          children: [

            /// AVATAR
            Container(
              width: 64,
              height: 64,

              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,

                color: Colors.white
                    .withValues(
                  alpha: 0.08,
                ),
              ),

              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 18),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  Text(
                    title,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize: 20,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    subtitle,
                    style:
                    TextStyle(
                      color: Colors
                          .white
                          .withValues(
                        alpha:
                        0.7,
                      ),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// CALL BUTTON
            GestureDetector(
              onTap: isCurrentUser
                  ? null
                  : () {
                _startCall(
                  userId: userId,
                  userName:
                  title,
                );
              },

              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds:
                  250,
                ),

                width: 58,
                height: 58,

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  color:
                  isCurrentUser
                      ? Colors
                      .grey
                      .withValues(
                    alpha:
                    0.2,
                  )
                      : Colors
                      .green,

                  boxShadow:
                  isCurrentUser
                      ? []
                      : [
                    BoxShadow(
                      blurRadius:
                      14,
                      spreadRadius:
                      1,
                      color: Colors
                          .green
                          .withValues(
                        alpha:
                        0.35,
                      ),
                    ),
                  ],
                ),

                child: Icon(
                  isCurrentUser
                      ? Icons.person
                      : Icons.call,

                  color:
                  Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF020617),

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(22),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [

              /// HEADER
              Row(
                children: [

                  Container(
                    width: 58,
                    height: 58,

                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),

                      color: Colors
                          .white
                          .withValues(
                        alpha:
                        0.08,
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .video_call_rounded,
                      color:
                      Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        const Text(
                          "QuickBlox Calls",
                          style:
                          TextStyle(
                            color: Colors
                                .white,
                            fontSize:
                            28,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          "Connected User ID : "
                              "${_qbService.currentUserId ?? '-'}",

                          style:
                          TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                              0.7,
                            ),
                            fontSize:
                            14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                "Available Contacts",
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.9,
                  ),
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              /// CONTACT LIST
              Expanded(
                child: ListView(
                  physics:
                  const BouncingScrollPhysics(),

                  children: [

                    _callCard(
                      title: "Siva",
                      subtitle:
                      "Tap to start video call",
                      userId: 142487337,
                      icon:
                      Icons.person_rounded,
                    ),

                    _callCard(
                      title:
                      "SivaCrafft",
                      subtitle:
                      "Tap to start video call",
                      userId: 142487335,
                      icon:
                      Icons.person_outline,
                    ),
                  ],
                ),
              ),

              /// CALLING LOADER
              if (_isCalling)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),

                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),

                    color: Colors.white
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),

                  child: const Row(
                    children: [

                      SizedBox(
                        width: 22,
                        height: 22,

                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors.white,
                        ),
                      ),

                      SizedBox(width: 14),

                      Text(
                        "Starting Call...",
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}