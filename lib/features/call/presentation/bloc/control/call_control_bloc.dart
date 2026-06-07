import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repository/call_repository.dart';

import 'call_control_event.dart';
import 'call_controll_state.dart';

class CallControlBloc
    extends Bloc<
        CallControlEvent,
        CallControlState> {
  final CallRepository repository;

  final String sessionId;

  CallControlBloc({
    required this.repository,
    required this.sessionId,
  }) : super(
    const CallControlState(),
  ) {
    on<ToggleMute>(
      _mute,
    );

    on<ToggleVideo>(
      _video,
    );

    on<SwitchCameraRequested>(
      _switchCamera,
    );
  }

  Future<void> _mute(
      ToggleMute event,
      Emitter<CallControlState> emit,
      ) async {
    final newValue =
    !state.muted;

    await repository.mute(
      sessionId,
      !newValue,
    );

    emit(
      state.copyWith(
        muted: newValue,
      ),
    );
  }

  Future<void> _video(
      ToggleVideo event,
      Emitter<CallControlState> emit,
      ) async {
    final newValue =
    !state.videoEnabled;

    await repository.video(
      sessionId,
      newValue,
    );

    emit(
      state.copyWith(
        videoEnabled: newValue,
      ),
    );
  }

  Future<void> _switchCamera(
      SwitchCameraRequested event,
      Emitter<CallControlState> emit,
      ) async {
    await repository.switchCamera(
      sessionId,
    );
  }
}