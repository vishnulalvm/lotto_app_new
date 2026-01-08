import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../data/services/audio_service.dart';

/// Helper class for providing tactile and audio feedback
/// Combines haptic feedback with sound effects for consistent UI interactions
class FeedbackHelper {
  static final AudioService _audioService = AudioService();
  
  // Track if we've triggered initialization
  static bool _initStarted = false;
  static bool _isReady = false;

  /// Initialize the audio service AND warm it up
  /// Call this early in app startup (e.g., in main() or splash screen)
  /// to ensure sounds are ready when needed
  /// 
  /// IMPORTANT: You MUST call this before using any feedback methods
  /// to ensure first-tap audio works!
  static Future<void> initialize() async {
    if (_isReady) return;
    if (_initStarted) {
      // Wait for existing initialization
      while (!_audioService.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      // Ensure warm-up is complete
      await _audioService.ensureWarmedUp();
      _isReady = true;
      return;
    }
    
    _initStarted = true;
    
    try {
      // Initialize and warm up
      await _audioService.initialize();
      await _audioService.ensureWarmedUp();
      _isReady = true;
    } catch (e) {
      // Log but don't crash - audio is non-critical
      debugPrint('FeedbackHelper: Audio initialization failed - $e');
    }
  }

  /// Ensure initialization has started (non-blocking)
  static void _ensureInitStarted() {
    if (!_initStarted) {
      _initStarted = true;
      // Initialize and warm up in background
      _audioService.initialize().then((_) {
        _audioService.ensureWarmedUp();
      });
    }
  }

  /// Play light click feedback (both haptic and sound)
  /// Use this for standard button taps, list item selections, etc.
  static void lightClick() {
    // Ensure audio service initialization has started
    _ensureInitStarted();
    
    // Play haptic feedback immediately - this is always fast
    HapticFeedback.lightImpact();

    // Play click sound (fire and forget)
    _audioService.playClickSound();
  }

  /// Play medium click feedback (both haptic and sound)
  /// Use this for more significant actions like expanding sections, confirmations
  static void mediumClick() {
    _ensureInitStarted();
    
    HapticFeedback.mediumImpact();
    _audioService.playClickSound();
  }

  /// Play heavy click feedback (both haptic and sound)
  /// Use this for destructive actions or major state changes
  static void heavyClick() {
    _ensureInitStarted();
    
    HapticFeedback.heavyImpact();
    _audioService.playClickSound();
  }

  /// Play selection feedback (both haptic and sound)
  /// Use this for toggle switches, radio buttons, checkboxes
  static void selectionClick() {
    _ensureInitStarted();
    
    HapticFeedback.selectionClick();
    _audioService.playClickSound();
  }

  /// Play celebration feedback (haptic + celebration sound)
  /// Use this for winning states, achievements, etc.
  static void celebration() {
    _ensureInitStarted();
    
    HapticFeedback.heavyImpact();
    _audioService.playCelebrationSound();
  }

  /// Play only haptic feedback without sound
  /// Use when sound would be inappropriate but haptic is desired
  static void hapticOnly() {
    HapticFeedback.lightImpact();
  }

  /// Play medium haptic feedback without sound
  static void hapticMedium() {
    HapticFeedback.mediumImpact();
  }

  /// Play only sound feedback without haptic
  /// Use when haptic would be inappropriate but sound is desired
  static void soundOnly() {
    _ensureInitStarted();
    _audioService.playClickSound();
  }

  /// Play celebration sound only (no haptic)
  static void celebrationSoundOnly() {
    _ensureInitStarted();
    _audioService.playCelebrationSound();
  }

  /// Check if sound effects are enabled
  static bool get isSoundEnabled => _audioService.isSoundEnabled;

  /// Check if audio service is fully ready (initialized + warmed up)
  static bool get isAudioReady => _audioService.isInitialized && _audioService.isWarmedUp;

  /// Get the sound enabled listenable for UI updates
  static ValueListenable<bool> get soundEnabledListenable => _audioService.isSoundEnabledListenable;

  /// Toggle sound on/off
  static Future<void> setSoundEnabled(bool enabled) async {
    await _audioService.setSoundEnabled(enabled);
  }
}

// Helper function for debug printing (avoids import in some cases)
void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}