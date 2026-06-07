abstract class CallControlEvent {}

class ToggleMute extends CallControlEvent {}

class ToggleVideo extends CallControlEvent {}

class SwitchCameraRequested
    extends CallControlEvent {}

class ToggleSpeaker
    extends CallControlEvent {}