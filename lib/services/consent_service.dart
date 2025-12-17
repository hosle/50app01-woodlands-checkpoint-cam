import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage user consent using the Google UMP SDK.
/// 
/// This service handles:
/// - Requesting consent information updates
/// - Loading and showing consent forms
/// - Checking if ads can be requested
/// - Managing privacy options entry point
/// 
/// Reference: https://developers.google.com/admob/flutter/privacy
class ConsentService {
  ConsentService._();
  
  static final ConsentService instance = ConsentService._();
  
  bool _isInitialized = false;
  bool _canRequestAds = false;
  
  /// Whether ads can be requested based on user consent.
  bool get canRequestAds => _canRequestAds;
  
  /// Whether the consent service has been initialized.
  bool get isInitialized => _isInitialized;
  
  /// Initialize consent management and request consent info update.
  /// 
  /// This should be called at every app launch before loading ads.
  /// Returns true if ads can be requested after consent gathering.
  Future<bool> initialize({
    List<String>? testDeviceIds,
    DebugGeography? debugGeography,
  }) async {
    try {
      // Create consent request parameters
      ConsentRequestParameters params;
      
      if (testDeviceIds != null || debugGeography != null) {
        // Debug settings for testing
        final debugSettings = ConsentDebugSettings(
          testIdentifiers: testDeviceIds ?? [],
          debugGeography: debugGeography,
        );
        params = ConsentRequestParameters(consentDebugSettings: debugSettings);
        debugPrint('ConsentService: Using debug settings with geography: $debugGeography');
      } else {
        params = ConsentRequestParameters();
      }
      
      // Request an update to consent information
      await _requestConsentInfoUpdate(params);
      
      // Load and show consent form if required
      await _loadAndShowConsentFormIfRequired();
      
      // Check if ads can be requested
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      _isInitialized = true;
      
      debugPrint('ConsentService: Initialized, canRequestAds: $_canRequestAds');
      
      return _canRequestAds;
    } catch (e) {
      debugPrint('ConsentService: Error during initialization: $e');
      // Even if consent gathering fails, check if we can still request ads
      // based on previous consent status
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      _isInitialized = true;
      return _canRequestAds;
    }
  }
  
  /// Request an update to consent information.
  Future<void> _requestConsentInfoUpdate(ConsentRequestParameters params) async {
    final completer = Completer<void>();
    
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        debugPrint('ConsentService: Consent info updated successfully');
        completer.complete();
      },
      (FormError error) {
        debugPrint('ConsentService: Error updating consent info: ${error.message}');
        completer.completeError(error);
      },
    );
    
    return completer.future;
  }
  
  /// Load and show consent form if required.
  Future<void> _loadAndShowConsentFormIfRequired() async {
    final completer = Completer<void>();
    
    ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError) {
      if (loadAndShowError != null) {
        debugPrint('ConsentService: Error loading/showing consent form: ${loadAndShowError.message}');
        // Don't complete with error - consent may have been gathered successfully
        // or no form was required
      } else {
        debugPrint('ConsentService: Consent form handled successfully');
      }
      completer.complete();
    });
    
    return completer.future;
  }
  
  /// Check if a privacy options entry point is required.
  /// 
  /// Use this to determine if you need to show a "Privacy Settings" button
  /// in your app's UI.
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }
  
  /// Show the privacy options form.
  /// 
  /// Call this when the user taps on your "Privacy Settings" button.
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint('ConsentService: Error showing privacy options form: ${formError.message}');
      } else {
        debugPrint('ConsentService: Privacy options form shown successfully');
      }
      completer.complete();
    });
    
    return completer.future;
  }
  
  /// Reset consent state.
  /// 
  /// WARNING: This is for testing only. Do not use in production.
  void reset() {
    ConsentInformation.instance.reset();
    _isInitialized = false;
    _canRequestAds = false;
    debugPrint('ConsentService: Consent state reset');
  }
  
  /// Refresh consent status without showing any forms.
  /// 
  /// Use this to re-check if ads can be requested after the user
  /// has interacted with the privacy options form.
  Future<bool> refreshConsentStatus() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    debugPrint('ConsentService: Refreshed consent status, canRequestAds: $_canRequestAds');
    return _canRequestAds;
  }
}
