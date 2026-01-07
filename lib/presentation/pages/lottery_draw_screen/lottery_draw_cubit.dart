import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

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

    return LotteryDrawState(
      isDrawing: false,
      currentTick: 0,
      mainLetter1: initialLotteryLetter ?? 'B',
      mainLetter2: 'A', // Default to first letter of series 1
      mainDigits: [8, 5, 6, 2, 8, 1],
      timerValue: '30239',
      seriesLetters: defaultSeriesLetters,
      windowDigits: {
        1: [2, 7, 9, 4],
        2: [9, 7, 5, 5],
        3: [4, 3, 5, 5],
        4: [9, 9, 0, 1],
        5: [1, 4, 6, 8],
        6: [5, 8, 9, 2],
        7: [1, 0, 4, 7],
        8: [4, 2, 5, 3],
        9: [7, 8, 0, 3],
        10: [1, 2, 7, 8],
        11: [8, 0, 2, 5],
        12: [2, 5, 9, 4],
        13: [0, 4, 7, 9],
        14: [5, 1, 5, 1],
        15: [8, 5, 4, 6],
        16: [8, 9, 8, 3],
        17: [1, 8, 2, 1],
        18: [6, 8, 5, 7],
      },
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

  /// Waits for reels to finish spinning, then marks draw as complete
  void _scheduleDrawEnd() async {
    // Total spin duration: ~3 seconds (typical slot machine feel)
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!isClosed) {
      emit(state.copyWith(isDrawing: false));
    }
  }

  /// No longer needed - keeping for backward compatibility
  @Deprecated('Animation duration is now controlled by individual reels')
  Duration getAnimationDuration() {
    return const Duration(milliseconds: 100);
  }
}
