/// Compile-time constant. Set with `--dart-define=GOOGLE_PLAY=true`.
///
/// Defaults to `false` (F-Droid / open-source) when not defined.
const kIsGooglePlay = bool.fromEnvironment('GOOGLE_PLAY');
