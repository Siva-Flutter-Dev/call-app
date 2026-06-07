class CallControlState {
  final bool muted;

  final bool videoEnabled;

  final bool speakerEnabled;

  const CallControlState({
    this.muted = false,
    this.videoEnabled = true,
    this.speakerEnabled = false,
  });

  CallControlState copyWith({
    bool? muted,
    bool? videoEnabled,
    bool? speakerEnabled,
  }) {
    return CallControlState(
      muted: muted ?? this.muted,
      videoEnabled:
      videoEnabled ??
          this.videoEnabled,
      speakerEnabled:
      speakerEnabled ??
          this.speakerEnabled,
    );
  }
}