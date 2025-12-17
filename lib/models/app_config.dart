/// Application build-time configuration.
///
/// Use `--dart-define` flags when building to configure:
/// ```
/// flutter run --dart-define=NO_ADS=true
/// flutter build ios --dart-define=NO_ADS=true
/// flutter build apk --dart-define=NO_ADS=true
/// ```
class AppConfig {
  AppConfig._();

  /// Whether ads are disabled. Default is false (ads enabled).
  /// Set via `--dart-define=NO_ADS=true` at build time.
  static const bool noAds = bool.fromEnvironment('NO_ADS', defaultValue: false);
  static const bool noDebugEntry = bool.fromEnvironment(
    'NO_DEBUG_ENTRY',
    defaultValue: false,
  );
}
