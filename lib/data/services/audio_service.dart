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

  // Audio file names
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
  bool _isWarmedUp = false;
  
  // Use a fresh completer for each initialization attempt
  Completer<void>? _initCompleter;

  /// Stream getter for widgets to listen to sound state changes
  ValueListenable<bool> get isSoundEnabledListenable => _isSoundEnabledNotifier;

  /// Get current sound enabled state
  bool get isSoundEnabled => _isSoundEnabledNotifier.value;

  /// Returns true if the service has been initialized successfully
  bool get isInitialized => _isInitialized;
  
  /// Returns true if audio is fully warmed up and ready for instant playback
  bool get isWarmedUp => _isWarmedUp;

  /// Initialize the audio service
  /// Must be called before using any audio functionality.
  /// Safe to call multiple times - only initializes once.
  Future<void> initialize() async {
    // If already initialized, return immediately
    if (_isInitialized) {
      return;
    }

    // If initialization is in progress, wait for it to complete
    if (_isInitializing && _initCompleter != null) {
      return _initCompleter!.future;
    }

    // Mark as initializing and create fresh completer
    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      // 1. Load sound preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_soundEnabledKey) ?? true;
      _isSoundEnabledNotifier.value = enabled;

      // 2. Configure FlameAudio to use the assets directory
      FlameAudio.audioCache.prefix = 'assets/';

      // 3. Pre-load audio files into cache
      await Future.wait([
        FlameAudio.audioCache.load(_clickSoundFile),
        FlameAudio.audioCache.load(_celebrationSoundFile),
      ]);

      // 4. Create AudioPools concurrently for faster initialization
      final results = await Future.wait([
        FlameAudio.createPool(_clickSoundFile, maxPlayers: 4),
        FlameAudio.createPool(_celebrationSoundFile, maxPlayers: 2),
      ]);

      _clickSoundPool = results[0];
      _celebrationSoundPool = results[1];

      // 5. Mark initialization as successful
      _isInitialized = true;
      _isInitializing = false;
      _initCompleter?.complete();

      debugPrint('AudioService: Initialized successfully');
      
      // 6. Warm up AFTER marking initialized (so it doesn't block)
      // This runs in background
      _performWarmUp();
      
    } catch (e, stack) {
      debugPrint('AudioService: Initialization failed - $e');
      debugPrint('Stack: $stack');
      
      // Reset state to allow retry
      _isInitialized = false;
      _isInitializing = false;
      _initCompleter?.completeError(e, stack);
      _initCompleter = null;
    }
  }

  /// Perform audio warm-up to eliminate first-play latency
  /// This actually plays sounds at very low (but audible) volume to activate
  /// the native audio pipeline
  Future<void> _performWarmUp() async {
    if (_isWarmedUp) return;
    
    try {
      // Wait a tiny bit for the pools to be fully ready
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Play at VERY low volume (0.01) - inaudible but activates the pipeline
      // This is the key fix - zero volume doesn't always activate native audio
      _clickSoundPool?.start(volume: 0.01);
      
      // Small delay then warm up celebration too
      await Future.delayed(const Duration(milliseconds: 100));
      _celebrationSoundPool?.start(volume: 0.01);
      
      _isWarmedUp = true;
      debugPrint('AudioService: Warm-up complete - ready for instant playback');
    } catch (e) {
      debugPrint('AudioService: Warm-up failed (non-critical) - $e');
      // Still mark as warmed up to avoid repeated attempts
      _isWarmedUp = true;
    }
  }

  /// Force warm-up if needed (call this after initialization if you want to ensure instant playback)
  Future<void> ensureWarmedUp() async {
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isWarmedUp) {
      await _performWarmUp();
    }
  }

  /// Play the click sound effect
  /// Returns immediately without waiting for sound to finish
  /// Uses AudioPool for instant playback with pre-loaded sounds
  void playClickSound() {
    // Only play if initialized and sounds are enabled
    if (!_isInitialized || !isSoundEnabled) {
      // If not initialized, try to initialize in background
      if (!_isInitialized && !_isInitializing) {
        initialize();
      }
      return;
    }

    final pool = _clickSoundPool;
    if (pool == null) return;

    try {
      // Start playing from the pool - instant playback
      pool.start(volume: 0.4);
    } catch (e) {
      debugPrint('AudioService: Error playing click sound - $e');
    }
  }

  /// Play the click sound with guaranteed initialization
  /// Use this for critical UI interactions where sound must play
  Future<void> playClickSoundAsync() async {
    if (!isSoundEnabled) return;

    if (!_isInitialized) {
      await initialize();
    }

    final pool = _clickSoundPool;
    if (pool == null) return;

    try {
      pool.start(volume: 0.4);
    } catch (e) {
      debugPrint('AudioService: Error playing click sound - $e');
    }
  }

  /// Play the celebration sound effect
  /// Used for winning lottery scratch cards
  void playCelebrationSound() {
    if (!_isInitialized || !isSoundEnabled) {
      if (!_isInitialized && !_isInitializing) {
        initialize();
      }
      return;
    }

    final pool = _celebrationSoundPool;
    if (pool == null) return;

    try {
      pool.start(volume: 0.8);
    } catch (e) {
      debugPrint('AudioService: Error playing celebration sound - $e');
    }
  }

  /// Play celebration sound with guaranteed initialization
  Future<void> playCelebrationSoundAsync() async {
    if (!isSoundEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    final pool = _celebrationSoundPool;
    if (pool == null) return;

    try {
      pool.start(volume: 0.8);
    } catch (e) {
      debugPrint('AudioService: Error playing celebration sound - $e');
    }
  }

  /// Set sound enabled state and persist to SharedPreferences
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabledNotifier.value = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      debugPrint('AudioService: Error persisting sound preference - $e');
    }
  }

  /// Dispose of audio resources
  Future<void> dispose() async {
    FlameAudio.audioCache.clearAll();
    _clickSoundPool = null;
    _celebrationSoundPool = null;
    _isSoundEnabledNotifier.dispose();
    _isInitialized = false;
    _isInitializing = false;
    _isWarmedUp = false;
    _initCompleter = null;
  }
}