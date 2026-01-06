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

  const LotteryDrawState({
    required this.isDrawing,
    required this.currentTick,
    required this.mainLetter1,
    required this.mainLetter2,
    required this.mainDigits,
    required this.timerValue,
    required this.windowDigits,
  });

  factory LotteryDrawState.initial() {
    return LotteryDrawState(
      isDrawing: false,
      currentTick: 0,
      mainLetter1: 'B',
      mainLetter2: 'V',
      mainDigits: [8, 5, 6, 2, 8, 1],
      timerValue: '30239',
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
  }) {
    return LotteryDrawState(
      isDrawing: isDrawing ?? this.isDrawing,
      currentTick: currentTick ?? this.currentTick,
      mainLetter1: mainLetter1 ?? this.mainLetter1,
      mainLetter2: mainLetter2 ?? this.mainLetter2,
      mainDigits: mainDigits ?? this.mainDigits,
      timerValue: timerValue ?? this.timerValue,
      windowDigits: windowDigits ?? this.windowDigits,
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
      ];
}

// Cubit
class LotteryDrawCubit extends Cubit<LotteryDrawState> {
  Timer? _drawTimer;
  final Random _random = Random();

  LotteryDrawCubit() : super(LotteryDrawState.initial());

  String _getRandomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[_random.nextInt(letters.length)];
  }

  int _getRandomDigit() {
    return _random.nextInt(10);
  }

  void startDraw() {
    if (state.isDrawing) return;

    emit(state.copyWith(
      isDrawing: true,
      currentTick: 0,
    ));

    // Cancel any existing timer
    _drawTimer?.cancel();

    // Animate for 3 seconds (60 ticks * 50ms = 3000ms)
    _drawTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (timer.tick >= 60) {
        timer.cancel();
        emit(state.copyWith(
          isDrawing: false,
          currentTick: 0,
        ));
        return;
      }

      // Update all values
      final newWindowDigits = <int, List<int>>{};
      for (int i = 1; i <= 18; i++) {
        newWindowDigits[i] = List.generate(4, (_) => _getRandomDigit());
      }

      emit(state.copyWith(
        currentTick: timer.tick,
        mainLetter1: _getRandomLetter(),
        mainLetter2: _getRandomLetter(),
        mainDigits: List.generate(6, (_) => _getRandomDigit()),
        timerValue: _random.nextInt(99999).toString().padLeft(5, '0'),
        windowDigits: newWindowDigits,
      ));
    });
  }

  Duration getAnimationDuration() {
    if (!state.isDrawing) return const Duration(milliseconds: 200);

    final progress = state.currentTick / 60.0; // 0.0 to 1.0
    final durationMs = 50 + (progress * 350); // 50ms to 400ms
    return Duration(milliseconds: durationMs.toInt());
  }

  @override
  Future<void> close() {
    _drawTimer?.cancel();
    return super.close();
  }
}
