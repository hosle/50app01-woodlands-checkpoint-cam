import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Class to manage application secrets loaded from secrets.json
/// This file should not be committed to version control
class AppSecrets {
  final String androidBannerAdUnitId;
  final String iosBannerAdUnitId;
  final String androidNativeAdUnitId;
  final String iosNativeAdUnitId;

  // Test ad unit IDs from Google AdMob documentation
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  static const String _testAndroidBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _testIosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2435281174';
  static const String _testAndroidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testIosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  AppSecrets._({
    required this.androidBannerAdUnitId,
    required this.iosBannerAdUnitId,
    required this.androidNativeAdUnitId,
    required this.iosNativeAdUnitId,
  });

  static AppSecrets? _instance;

  /// Get the singleton instance of AppSecrets
  static AppSecrets get instance {
    if (_instance == null) {
      throw StateError(
        'AppSecrets not initialized. Call AppSecrets.load() first.',
      );
    }
    return _instance!;
  }

  /// Check if secrets are loaded
  static bool get isLoaded => _instance != null;

  /// Load secrets from secrets.json file
  /// Returns true if successful, false otherwise
  static Future<bool> load() async {
    try {
      final file = File('secrets.json');

      if (!await file.exists()) {
        debugPrint('WARNING: secrets.json not found. Using test ad unit IDs.');
        // Use test ad unit IDs as fallback
        _instance = AppSecrets._(
          androidBannerAdUnitId: 'ca-app-pub-3940256099942544/9214589741',
          iosBannerAdUnitId: 'ca-app-pub-3940256099942544/2435281174',
          androidNativeAdUnitId: 'ca-app-pub-3940256099942544/2247696110',
          iosNativeAdUnitId: 'ca-app-pub-3940256099942544/3986624511',
        );
        return false;
      }

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;

      final admob = json['admob'] as Map<String, dynamic>;
      final android = admob['android'] as Map<String, dynamic>;
      final ios = admob['ios'] as Map<String, dynamic>;

      _instance = AppSecrets._(
        androidBannerAdUnitId: android['bannerAdUnitId'] as String,
        iosBannerAdUnitId: ios['bannerAdUnitId'] as String,
        androidNativeAdUnitId: android['nativeAdUnitId'] as String,
        iosNativeAdUnitId: ios['nativeAdUnitId'] as String,
      );

      debugPrint('AppSecrets loaded successfully');
      return true;
    } catch (e) {
      debugPrint('Error loading secrets.json: $e');
      debugPrint('Using test ad unit IDs as fallback');

      // Use test ad unit IDs as fallback
      _instance = AppSecrets._(
        androidBannerAdUnitId: 'ca-app-pub-3940256099942544/9214589741',
        iosBannerAdUnitId: 'ca-app-pub-3940256099942544/2435281174',
        androidNativeAdUnitId: 'ca-app-pub-3940256099942544/2247696110',
        iosNativeAdUnitId: 'ca-app-pub-3940256099942544/3986624511',
      );
      return false;
    }
  }

  /// Get the banner ad unit ID for the current platform
  /// Returns test ad unit ID for debug/profile builds, production ID for release builds
  String getBannerAdUnitId() {
    // Only use production ad unit IDs in release mode
    if (kReleaseMode) {
      return Platform.isAndroid ? androidBannerAdUnitId : iosBannerAdUnitId;
    }
    // Use test ad unit IDs for debug and profile builds
    debugPrint('Using TEST banner ad unit ID (non-release build)');
    return Platform.isAndroid
        ? _testAndroidBannerAdUnitId
        : _testIosBannerAdUnitId;
  }

  /// Get the native ad unit ID for the current platform
  /// Returns test ad unit ID for debug/profile builds, production ID for release builds
  String getNativeAdUnitId() {
    // Only use production ad unit IDs in release mode
    if (kReleaseMode) {
      return Platform.isAndroid ? androidNativeAdUnitId : iosNativeAdUnitId;
    }
    // Use test ad unit IDs for debug and profile builds
    debugPrint('Using TEST native ad unit ID (non-release build)');
    return Platform.isAndroid
        ? _testAndroidNativeAdUnitId
        : _testIosNativeAdUnitId;
  }
}
