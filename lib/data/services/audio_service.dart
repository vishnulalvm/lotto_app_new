import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio playback in the app
/// Handles click sounds and sound settings persistence using FlameAudio AudioPool
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String _soundEnabledKey = 'sound_effects_enabled';

  // Audio file names (audioplayers AssetSource expects path relative to assets/)
  // Using WAV format for better Android compatibility (no codec issues)
  static const String _clickSoundFile = 'audios/updatedtap.wav';
  static const String _celebrationSoundFile = 'audios/celebration.wav';

  // AudioPool instances for pre-loaded sounds
  AudioPool? _clickSoundPool;
  AudioPool? _celebrationSoundPool;

  // Use ValueNotifier to expose the sound state for Flutter widgets
  final ValueNotifier<bool> _isSoundEnabledNotifier = ValueNotifier<bool>(true);

  // Track initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Stream getter for widgets to listen to sound state changes
  ValueListenable<bool> get isSoundEnabledListenable => _isSoundEnabledNotifier;

  /// Get current sound enabled state (from the notifier value)
  bool get isSoundEnabled => _isSoundEnabledNotifier.value;

  /// Returns true if the service has been initialized successfully
  bool get isInitialized => _isInitialized;


  /// Initialize the audio service
  /// Must be called before using any audio functionality.
  /// Only runs once, subsequent calls wait for the first to complete.
  Future<void> initialize() async {
    // If already initialized, return immediately
    if (_isInitialized) {
      return;
    }

    // If initialization is in progress, wait for it to complete
    if (_isInitializing) {
      return _initCompleter.future;
    }

    // Mark as initializing
    _isInitializing = true;

    try {
      // 1. Load sound preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_soundEnabledKey) ?? true;
      _isSoundEnabledNotifier.value = enabled;

      // 2. Configure FlameAudio to use the assets directory
      FlameAudio.audioCache.prefix = 'assets/';

      // 3. First, try to load files into cache (simpler approach)
      try {
        await FlameAudio.audioCache.load(_clickSoundFile);
      } catch (e) {
        rethrow;
      }

      try {
        await FlameAudio.audioCache.load(_celebrationSoundFile);
      } catch (e) {
        rethrow;
      }

      // 4. Create AudioPool for click sound (allows multiple simultaneous plays)
      try {
        _clickSoundPool = await FlameAudio.createPool(
          _clickSoundFile,
          maxPlayers: 3,
        );
      } catch (e) {
        rethrow;
      }

      // 5. Create AudioPool for celebration sound
      try {
        _celebrationSoundPool = await FlameAudio.createPool(
          _celebrationSoundFile,
          maxPlayers: 1,
        );
      } catch (e) {
        rethrow;
      }

      // 6. Mark initialization as successful
      _isInitialized = true;
      _isInitializing = false;

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e, stack) {
      // If initialization fails, reset state
      _isInitialized = false;
      _isInitializing = false;

      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, stack);
      }
    }
  }

  /// Play the click sound effect
  /// Returns immediately without waiting for sound to finish
  /// Uses AudioPool for instant playback with pre-loaded sounds
  void playClickSound() {
    // Only play if initialized and sounds are enabled
    if (!_isInitialized || !isSoundEnabled || _clickSoundPool == null) {
      return;
    }

    try {
      // Start playing from the pool - instant playback
      // The pool handles multiple simultaneous plays automatically
      _clickSoundPool!.start(volume: 0.9);
    } catch (e) {
      // Silently fail
    }
  }

  /// Play the celebration sound effect
  /// Used for winning lottery scratch cards
  void playCelebrationSound() {
    // Only play if initialized and sounds are enabled
    if (!_isInitialized || !isSoundEnabled || _celebrationSoundPool == null) {
      return;
    }

    try {
      // Start playing from the pool
      _celebrationSoundPool!.start(volume: 0.8);
    } catch (e) {
      // Silently fail
    }
  }

  /// Set sound enabled state and persist to SharedPreferences
  Future<void> setSoundEnabled(bool enabled) async {
    // 1. Update the ValueNotifier first (instant UI update)
    _isSoundEnabledNotifier.value = enabled;

    // 2. Persist the change
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error persisting sound preference: $e');
    }
  }

  /// Dispose of audio resources
  /// Call this when the app is terminating
  Future<void> dispose() async {
    // Clear all audio resources
    FlameAudio.audioCache.clearAll();
    _clickSoundPool = null;
    _celebrationSoundPool = null;

    _isSoundEnabledNotifier.dispose();
    _isInitialized = false;
    _isInitializing = false;
  }
}
