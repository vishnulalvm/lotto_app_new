import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';

// State
class LotteryDrawState extends Equatable {
  final bool isDrawing;
  final int currentTick;
  final String mainLetter1;
  final String mainLetter2;
  final List<int> mainDigits;
  final String timerValue;
  final Map<int, List<int>> windowDigits;
  final List<String> seriesLetters; // Available letters for the selected series

  const LotteryDrawState({
    required this.isDrawing,
    required this.currentTick,
    required this.mainLetter1,
    required this.mainLetter2,
    required this.mainDigits,
    required this.timerValue,
    required this.windowDigits,
    required this.seriesLetters,
  });

  factory LotteryDrawState.initial({String? initialLotteryLetter}) {
    // Default to Series 1 letters
    const defaultSeriesLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M'];

    // Create Random instance for initial state (one-time use)
    final random = Random();

    // Generate random initial values for better UX
    // Users will see different numbers each time they open the screen
    final randomMainDigits = List.generate(6, (_) => random.nextInt(10));
    final randomTimerValue = random.nextInt(99999).toString().padLeft(5, '0');
    final randomLetter2 = defaultSeriesLetters[random.nextInt(defaultSeriesLetters.length)];

    // Generate random window digits (18 windows, 4 digits each)
    final randomWindowDigits = <int, List<int>>{};
    for (int i = 1; i <= 18; i++) {
      randomWindowDigits[i] = List.generate(4, (_) => random.nextInt(10));
    }

    return LotteryDrawState(
      isDrawing: false,
      currentTick: 0,
      mainLetter1: initialLotteryLetter ?? 'B',
      mainLetter2: randomLetter2, // Random letter from series
      mainDigits: randomMainDigits, // Random digits instead of hardcoded
      timerValue: randomTimerValue, // Random timer instead of hardcoded
      seriesLetters: defaultSeriesLetters,
      windowDigits: randomWindowDigits, // Random window digits
    );
  }

  LotteryDrawState copyWith({
    bool? isDrawing,
    int? currentTick,
    String? mainLetter1,
    String? mainLetter2,
    List<int>? mainDigits,
    String? timerValue,
    Map<int, List<int>>? windowDigits,
    List<String>? seriesLetters,
  }) {
    return LotteryDrawState(
      isDrawing: isDrawing ?? this.isDrawing,
      currentTick: currentTick ?? this.currentTick,
      mainLetter1: mainLetter1 ?? this.mainLetter1,
      mainLetter2: mainLetter2 ?? this.mainLetter2,
      mainDigits: mainDigits ?? this.mainDigits,
      timerValue: timerValue ?? this.timerValue,
      windowDigits: windowDigits ?? this.windowDigits,
      seriesLetters: seriesLetters ?? this.seriesLetters,
    );
  }

  @override
  List<Object?> get props => [
        isDrawing,
        currentTick,
        mainLetter1,
        mainLetter2,
        mainDigits,
        timerValue,
        windowDigits,
        seriesLetters,
      ];
}

// Cubit
class LotteryDrawCubit extends Cubit<LotteryDrawState> {
  final Random _random = Random();
  Timer? _hapticTimer;

  LotteryDrawCubit() : super(LotteryDrawState.initial());

  String _getRandomLetter() {
    // Get random letter from the selected series
    if (state.seriesLetters.isEmpty) {
      return 'A';
    }
    return state.seriesLetters[_random.nextInt(state.seriesLetters.length)];
  }

  /// Updates the lottery letter (from dropdown selection)
  void updateLotteryLetter(String letter) {
    emit(state.copyWith(mainLetter1: letter));
  }

  /// Updates the available series letters (from series dropdown selection)
  void updateSeriesLetters(List<String> letters) {
    // Also update mainLetter2 to a letter from the new series
    final newLetter2 = letters.isNotEmpty ? letters[_random.nextInt(letters.length)] : 'A';
    emit(state.copyWith(
      seriesLetters: letters,
      mainLetter2: newLetter2,
    ));
  }

  /// Starts the draw by generating FINAL target numbers once
  /// The reels will spin autonomously until they reach these targets
  void startDraw() {
    if (state.isDrawing) return;

    // Play spinning sound with reduced volume (0.3 = 30% volume)
    FlameAudio.play('audios/spining_sound.mp3', volume: 0.3);

    // Haptic feedback when rotation starts
    HapticFeedback.lightImpact();

    // Start periodic haptic feedback during rotation (every 150ms for slot machine feel)
    _startRotationHaptics();

    // Generate final target digits (not random per tick!)
    final finalMainDigits = List.generate(6, (_) => _random.nextInt(10));
    // Keep the selected lottery letter, only randomize the second letter
    final finalMainLetter1 = state.mainLetter1; // Use the selected lottery letter
    final finalMainLetter2 = _getRandomLetter();
    final finalTimerValue = _random.nextInt(99999).toString().padLeft(5, '0');

    final finalWindowDigits = <int, List<int>>{};
    for (int i = 1; i <= 18; i++) {
      finalWindowDigits[i] = List.generate(4, (_) => _random.nextInt(10));
    }

    // Emit ONCE with final targets - reels will spin themselves
    emit(state.copyWith(
      isDrawing: true,
      currentTick: 0,
      mainLetter1: finalMainLetter1,
      mainLetter2: finalMainLetter2,
      mainDigits: finalMainDigits,
      timerValue: finalTimerValue,
      windowDigits: finalWindowDigits,
    ));

    // Schedule the end of the draw (when reels should stop)
    _scheduleDrawEnd();
  }

  /// Starts periodic haptic feedback during rotation
  void _startRotationHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      HapticFeedback.selectionClick();
    });
  }

  /// Stops the periodic haptic feedback
  void _stopRotationHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  /// Waits for reels to finish spinning, then marks draw as complete
  void _scheduleDrawEnd() async {
    // Total spin duration: 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!isClosed) {
      // Stop periodic haptic feedback
      _stopRotationHaptics();

      // Final haptic feedback when rotation stops
      HapticFeedback.mediumImpact();
      emit(state.copyWith(isDrawing: false));
    }
  }

  @override
  Future<void> close() {
    _hapticTimer?.cancel();
    return super.close();
  }

  /// No longer needed - keeping for backward compatibility
  @Deprecated('Animation duration is now controlled by individual reels')
  Duration getAnimationDuration() {
    return const Duration(milliseconds: 100);
  }
}
