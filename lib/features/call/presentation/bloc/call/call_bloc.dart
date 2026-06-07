import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/callkit_actions.dart';
import '../../../../../core/services/callkit_service.dart';
import '../../../domain/entities/active_call_entity.dart';
import '../../../domain/repository/call_repository.dart';

import 'call_events.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository repository;

  final CallKitService callKitService;

  StreamSubscription? _incomingSub;

  StreamSubscription? _rtcSub;

  StreamSubscription? _callKitSub;

  ActiveCall? currentCall;

  CallBloc({
    required this.repository,
    required this.callKitService,
  }) : super(CallInitial()) {
    on<IncomingCallReceived>(
      _incomingCall,
    );

    on<StartOutgoingCall>(
      _startCall,
    );

    on<AcceptCallRequested>(
      _acceptCall,
    );

    on<RejectCallRequested>(
      _rejectCall,
    );

    on<HangupRequested>(
      _hangup,
    );

    on<CallAcceptedByRemote>((_, emit) {

        if (currentCall == null) {
          return;
        }

        if (currentCall!.isVideo) {

          emit(
            VideoCallStarted(
              currentCall!,
            ),
          );

        } else {

          emit(
            AudioCallStarted(
              currentCall!,
            ),
          );
        }
      },);

    on<CallRejectedByRemote>((_, emit) {

        currentCall = null;

        emit(
          CallRejected(),
        );
      },);

    on<CallEndedByRemote>((_, emit) {

        currentCall = null;

        emit(
          CallEnded(),
        );
      },);

    _listenStreams();
  }

  void _listenStreams() {
    _incomingSub = repository.incomingCalls().listen((call) {
            add(
              IncomingCallReceived(
                call,
              ),
            );
          });

    _rtcSub = repository.callEvents().listen((event) {

            switch (event['type']) {

              case 'accepted':
                add(
                  CallAcceptedByRemote(),
                );
                break;

              case 'rejected':
                add(
                  CallRejectedByRemote(),
                );
                break;

              case 'hangup':
                add(
                  CallEndedByRemote(),
                );
                break;

              case 'no_answer':
                add(
                  CallEndedByRemote(),
                );
                break;
            }
          });

    _callKitSub = callKitService.events.listen((event) {
            if (event is CallAcceptedAction) {
              add(
                AcceptCallRequested(
                  event.sessionId,
                ),
              );
            }

            if (event is CallRejectedAction) {
              add(
                RejectCallRequested(
                  event.sessionId,
                ),
              );
            }

            if (event is CallEndedAction) {
              add(
                HangupRequested(
                  event.sessionId,
                ),
              );
            }
          });
  }

  Future<void> _incomingCall(
      IncomingCallReceived event,
      Emitter<CallState> emit,
      ) async {
    currentCall = event.call;

    emit(
      IncomingCallKitShown(),
    );
  }

  Future<void> _startCall(
      StartOutgoingCall event,
      Emitter<CallState> emit,
      ) async {
    emit(
      CallLoading(),
    );

    final sessionId =
    await repository.startCall(
      opponents: event.opponents,
      isVideo: event.isVideo,
      userName: event.userName,
    );

    if (sessionId == null) {
      emit(
        CallError(
          'Call Failed',
        ),
      );
      return;
    }

    currentCall = ActiveCall(
      sessionId: sessionId,
      remoteUserId: event.opponents.first,
      remoteName: event.userName,
      isVideo: event.isVideo,
      direction: CallDirection.outgoing,
    );

    emit(
      OutgoingCallState(
        sessionId,
      ),
    );
  }

  Future<void> _acceptCall(
      AcceptCallRequested event,
      Emitter<CallState> emit,
      ) async {
    if (currentCall == null) return;

    emit(
      ConnectingCall(),
    );

    await repository.acceptCall(
      event.sessionId,
    );

    if (currentCall!.isVideo) {
      emit(
        VideoCallStarted(
          currentCall!,
        ),
      );
    } else {
      emit(
        AudioCallStarted(
          currentCall!,
        ),
      );
    }
  }

  Future<void> _rejectCall(
      RejectCallRequested event,
      Emitter<CallState> emit,
      ) async {

    await repository.rejectCall(
      event.sessionId,
    );

    currentCall = null;

    emit(
      CallRejected(),
    );
  }

  Future<void> _hangup(
      HangupRequested event,
      Emitter<CallState> emit,
      ) async {

    await repository.hangup(
      event.sessionId,
    );

    currentCall = null;

    emit(
      CallEnded(),
    );
  }

  @override
  Future<void> close() async {
    await _incomingSub?.cancel();

    await _rtcSub?.cancel();

    await _callKitSub?.cancel();

    return super.close();
  }
}