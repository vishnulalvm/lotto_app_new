import 'dart:async';
import 'package:flutter/foundation.dart'; // For ValueNotifier and debugPrint
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio playback in the app
/// Handles click sounds and sound settings persistence
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String _soundEnabledKey = 'sound_effects_enabled';

  // Use multiple click players for rapid-fire playback without interruption
  final List<AudioPlayer> _clickPlayers = [];
  int _currentClickPlayerIndex = 0;
  AudioPlayer? _celebrationPlayer;

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

      // 2. Dispose of existing players if any (handles hot reload scenarios)
      for (var player in _clickPlayers) {
        await player.dispose();
      }
      _clickPlayers.clear();
      _currentClickPlayerIndex = 0;
      await _celebrationPlayer?.dispose();
      _celebrationPlayer = null;

      // 3. Initialize audio players (3 click players for rapid-fire playback)
      for (int i = 0; i < 3; i++) {
        final player = AudioPlayer();
        await player.setAsset('assets/audios/updatedtap.mp3');
        await player.setVolume(0.9);
        await player.setLoopMode(LoopMode.off);
        _clickPlayers.add(player);
      }

      _celebrationPlayer = AudioPlayer();

      // 4. Pre-load celebration sound
      await _celebrationPlayer!.setAsset('assets/audios/celebration.mp3');

      // 5. Set celebration volume and loop mode
      await _celebrationPlayer!.setVolume(0.8);
      await _celebrationPlayer!.setLoopMode(LoopMode.off);

      // 7. Mark initialization as successful
      _isInitialized = true;
      _isInitializing = false;

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }

      debugPrint('AudioService initialized successfully.');
    } catch (e, stack) {
      // If initialization fails, log the error and reset state
      debugPrint('AudioService Initialization Failed: $e');
      debugPrint('Stack trace: $stack');

      _isInitialized = false;
      _isInitializing = false;

      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, stack);
      }

      // Clean up on failure
      for (var player in _clickPlayers) {
        await player.dispose();
      }
      _clickPlayers.clear();
      await _celebrationPlayer?.dispose();
      _celebrationPlayer = null;
    }
  }

  /// Play the click sound effect
  /// Returns immediately without waiting for sound to finish
  /// Uses player pool for rapid-fire playback without interruption
  Future<void> playClickSound() async {
    // Only play if initialized and sounds are enabled
    if (!_isInitialized || !isSoundEnabled || _clickPlayers.isEmpty) {
      return;
    }

    try {
      // Get current player from pool
      final player = _clickPlayers[_currentClickPlayerIndex];

      // Cycle to next player for next click
      _currentClickPlayerIndex = (_currentClickPlayerIndex + 1) % _clickPlayers.length;

      // Play from beginning (using seek ensures restart if somehow still playing)
      unawaited(player.seek(Duration.zero));
      unawaited(player.play());
    } catch (e) {
      debugPrint('Error playing click sound: $e');
    }
  }

  /// Play the celebration sound effect
  /// Used for winning lottery scratch cards
  Future<void> playCelebrationSound() async {
    // Only play if initialized and sounds are enabled
    if (!_isInitialized || !isSoundEnabled || _celebrationPlayer == null) {
      return;
    }

    try {
      // Always seek to beginning and play (celebration plays once per win)
      await _celebrationPlayer!.seek(Duration.zero);
      await _celebrationPlayer!.play();
    } catch (e) {
      // If error occurs, try to recover by reloading the asset
      debugPrint('Error playing celebration sound: $e');
      try {
        await _celebrationPlayer!.setAsset('assets/audios/celebration.mp3');
        await _celebrationPlayer!.play();
      } catch (e2) {
        debugPrint('Failed to recover celebration player: $e2');
      }
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
    for (var player in _clickPlayers) {
      await player.dispose();
    }
    _clickPlayers.clear();
    await _celebrationPlayer?.dispose();
    _celebrationPlayer = null;
    _isSoundEnabledNotifier.dispose();
    _isInitialized = false;
    _isInitializing = false;
  }
}

