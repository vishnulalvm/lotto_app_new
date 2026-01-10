import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:lotto_app/data/services/lottery_draw_storage_service.dart';

// State
class LotteryDrawState extends Equatable {
  final bool isDrawing;
  final bool isLoading;
  final int currentTick;
  final String mainLetter1;
  final String mainLetter2;
  final List<int> mainDigits;
  final String timerValue;
  final Map<int, List<int>> windowDigits;
  final List<String> seriesLetters;
  final String lotteryName;

  const LotteryDrawState({
    required this.isDrawing,
    required this.isLoading,
    required this.currentTick,
    required this.mainLetter1,
    required this.mainLetter2,
    required this.mainDigits,
    required this.timerValue,
    required this.windowDigits,
    required this.seriesLetters,
    required this.lotteryName,
  });

  /// Loading state - shown while fetching from storage
  factory LotteryDrawState.loading() {
    final placeholderWindowDigits = <int, List<int>>{};
    for (int i = 1; i <= 18; i++) {
      placeholderWindowDigits[i] = [8, 4, 2, 7];
    }

    return LotteryDrawState(
      isDrawing: false,
      isLoading: true,
      currentTick: 0,
      mainLetter1: 'B',
      mainLetter2: 'K',
      mainDigits: const [3, 7, 1, 9, 0, 5],
      timerValue: '48261',
      windowDigits: placeholderWindowDigits,
      seriesLetters: const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M'],
      lotteryName: 'BHAGYATHARA',
    );
  }

  LotteryDrawState copyWith({
    bool? isDrawing,
    bool? isLoading,
    int? currentTick,
    String? mainLetter1,
    String? mainLetter2,
    List<int>? mainDigits,
    String? timerValue,
    Map<int, List<int>>? windowDigits,
    List<String>? seriesLetters,
    String? lotteryName,
  }) {
    return LotteryDrawState(
      isDrawing: isDrawing ?? this.isDrawing,
      isLoading: isLoading ?? this.isLoading,
      currentTick: currentTick ?? this.currentTick,
      mainLetter1: mainLetter1 ?? this.mainLetter1,
      mainLetter2: mainLetter2 ?? this.mainLetter2,
      mainDigits: mainDigits ?? this.mainDigits,
      timerValue: timerValue ?? this.timerValue,
      windowDigits: windowDigits ?? this.windowDigits,
      seriesLetters: seriesLetters ?? this.seriesLetters,
      lotteryName: lotteryName ?? this.lotteryName,
    );
  }

  @override
  List<Object?> get props => [
        isDrawing,
        isLoading,
        currentTick,
        mainLetter1,
        mainLetter2,
        mainDigits,
        timerValue,
        windowDigits,
        seriesLetters,
        lotteryName,
      ];

  Map<String, dynamic> toJson() {
    return {
      'mainLetter1': mainLetter1,
      'mainLetter2': mainLetter2,
      'mainDigits': mainDigits,
      'timerValue': timerValue,
      'windowDigits': windowDigits.map((key, value) => MapEntry(key.toString(), value)),
      'seriesLetters': seriesLetters,
      'lotteryName': lotteryName,
    };
  }

  factory LotteryDrawState.fromJson(Map<String, dynamic> json) {
    return LotteryDrawState(
      isDrawing: false,
      isLoading: false,
      currentTick: 0,
      mainLetter1: json['mainLetter1'] as String,
      mainLetter2: json['mainLetter2'] as String,
      mainDigits: List<int>.from(json['mainDigits'] as List),
      timerValue: json['timerValue'] as String,
      windowDigits: (json['windowDigits'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), List<int>.from(value as List)),
      ),
      seriesLetters: List<String>.from(json['seriesLetters'] as List),
      lotteryName: json['lotteryName'] as String,
    );
  }
}

// Cubit
class LotteryDrawCubit extends Cubit<LotteryDrawState> {
  final Random _random = Random();
  Timer? _hapticTimer;
  final LotteryDrawStorageService _storageService;

  /// IMPORTANT: Use this static method to create the cubit
  /// This ensures saved state is loaded BEFORE the cubit emits anything
  static Future<LotteryDrawCubit> create({
    LotteryDrawStorageService? storageService,
  }) async {
    final service = storageService ?? LotteryDrawStorageService();
    
    // Load saved state FIRST, before creating cubit
    final savedState = await service.loadDrawState();
    
    // Create cubit with the correct initial state
    final cubit = LotteryDrawCubit._internal(service, savedState);
    
    return cubit;
  }

  /// Internal constructor - don't call directly, use create() instead
  LotteryDrawCubit._internal(
    this._storageService,
    Map<String, dynamic>? savedState,
  ) : super(savedState != null
            ? LotteryDrawState.fromJson(savedState)
            : _createFirstTimeState()) {
    // If no saved state, save the initial random state
    if (savedState == null) {
      _saveCurrentState();
    }
  }

  /// Creates random state for first-time users
  static LotteryDrawState _createFirstTimeState() {
    final random = Random();
    const seriesLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M'];

    final randomMainDigits = List.generate(6, (_) => random.nextInt(10));
    final randomTimerValue = random.nextInt(99999).toString().padLeft(5, '0');
    final randomLetter2 = seriesLetters[random.nextInt(seriesLetters.length)];

    final randomWindowDigits = <int, List<int>>{};
    for (int i = 1; i <= 18; i++) {
      randomWindowDigits[i] = List.generate(4, (_) => random.nextInt(10));
    }

    return LotteryDrawState(
      isDrawing: false,
      isLoading: false,
      currentTick: 0,
      mainLetter1: 'B',
      mainLetter2: randomLetter2,
      mainDigits: randomMainDigits,
      timerValue: randomTimerValue,
      windowDigits: randomWindowDigits,
      seriesLetters: seriesLetters,
      lotteryName: 'BHAGYATHARA',
    );
  }

  /// Save current state to storage
  Future<void> _saveCurrentState() async {
    try {
      await _storageService.saveDrawState(state.toJson());
    } catch (e) {
      // Silently fail
    }
  }

  String _getRandomLetter() {
    if (state.seriesLetters.isEmpty) return 'A';
    return state.seriesLetters[_random.nextInt(state.seriesLetters.length)];
  }

  void updateLotteryLetter(String letter, {String? lotteryName}) {
    emit(state.copyWith(
      mainLetter1: letter,
      lotteryName: lotteryName,
    ));
    _saveCurrentState();
  }

  void updateSeriesLetters(List<String> letters) {
    final newLetter2 = letters.isNotEmpty 
        ? letters[_random.nextInt(letters.length)] 
        : 'A';
    emit(state.copyWith(
      seriesLetters: letters,
      mainLetter2: newLetter2,
    ));
    _saveCurrentState();
  }

  void startDraw() {
    if (state.isDrawing) return;

    FlameAudio.play('audios/spining_sound.mp3', volume: 0.3);
    HapticFeedback.lightImpact();
    _startRotationHaptics();

    final finalMainDigits = List.generate(6, (_) => _random.nextInt(10));
    final finalMainLetter1 = state.mainLetter1;
    final finalMainLetter2 = _getRandomLetter();
    final finalTimerValue = _random.nextInt(99999).toString().padLeft(5, '0');

    final finalWindowDigits = <int, List<int>>{};
    for (int i = 1; i <= 18; i++) {
      finalWindowDigits[i] = List.generate(4, (_) => _random.nextInt(10));
    }

    emit(state.copyWith(
      isDrawing: true,
      isLoading: false,
      currentTick: 0,
      mainLetter1: finalMainLetter1,
      mainLetter2: finalMainLetter2,
      mainDigits: finalMainDigits,
      timerValue: finalTimerValue,
      windowDigits: finalWindowDigits,
    ));

    _scheduleDrawEnd();
  }

  void _startRotationHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void _stopRotationHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  void _scheduleDrawEnd() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!isClosed) {
      _stopRotationHaptics();
      HapticFeedback.mediumImpact();

      emit(state.copyWith(isDrawing: false));

      // CRITICAL: Save the result after spin completes
      await _saveCurrentState();
    }
  }

  @override
  Future<void> close() {
    _hapticTimer?.cancel();
    return super.close();
  }

  @Deprecated('Animation duration is now controlled by individual reels')
  Duration getAnimationDuration() {
    return const Duration(milliseconds: 100);
  }
}