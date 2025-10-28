import 'package:flutter/services.dart';
import '../../data/services/audio_service.dart';

/// Helper class for providing tactile and audio feedback
/// Combines haptic feedback with sound effects for consistent UI interactions
class FeedbackHelper {
  static final AudioService _audioService = AudioService();

  /// Play light click feedback (both haptic and sound)
  /// Use this for standard button taps, list item selections, etc.
  static void lightClick() {
    // Play haptic feedback
    HapticFeedback.lightImpact();

    // Play click sound (fire and forget for instant response)
    _audioService.playClickSound();
  }

  /// Play medium click feedback (both haptic and sound)
  /// Use this for more significant actions like expanding sections, confirmations
  static void mediumClick() {
    // Play haptic feedback
    HapticFeedback.mediumImpact();

    // Play click sound (fire and forget for instant response)
    _audioService.playClickSound();
  }

  /// Play selection feedback (both haptic and sound)
  /// Use this for toggle switches, radio buttons, checkboxes
  static void selectionClick() {
    // Play haptic feedback
    HapticFeedback.selectionClick();

    // Play click sound (fire and forget for instant response)
    _audioService.playClickSound();
  }

  /// Play only haptic feedback without sound
  /// Use when sound would be inappropriate but haptic is desired
  static void hapticOnly() {
    HapticFeedback.lightImpact();
  }

  /// Play only sound feedback without haptic
  /// Use when haptic would be inappropriate but sound is desired
  static void soundOnly() {
    _audioService.playClickSound();
  }
}
