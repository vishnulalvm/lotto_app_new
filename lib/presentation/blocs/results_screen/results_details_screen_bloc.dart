import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/data/services/pdf_service.dart';
import 'package:lotto_app/data/services/prediction_match_service.dart';
import 'package:lotto_app/data/services/pattern_analysis_service.dart';
import 'package:lotto_app/data/services/predict_cache_service.dart';
import 'package:lotto_app/domain/usecases/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/lottery_result_text_formatter.dart';

class LotteryResultDetailsBloc
    extends Bloc<LotteryResultDetailsEvent, LotteryResultDetailsState> {
  final LotteryResultDetailsUseCase _useCase;

  // Store current unique ID for refresh functionality
  String? _currentUniqueId;

  // Timer for live hour background refresh
  Timer? _liveRefreshTimer;

  // Store previous result for detecting newly updated tickets
  LotteryResultModel? _previousResult;

  // Minimum search length
  static const int _minSearchLength = 4;

  LotteryResultDetailsBloc(this._useCase)
      : super(const LotteryResultDetailsInitial()) {
    on<LoadLotteryResultDetailsEvent>(_onLoadLotteryResultDetails);
    on<RefreshLotteryResultDetailsEvent>(_onRefreshLotteryResultDetails);
    on<BackgroundRefreshResultDetailsEvent>(_onBackgroundRefreshResultDetails);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<FilterChangedEvent>(_onFilterChanged);
    on<ToggleSaveResultEvent>(_onToggleSaveResult);
    on<CheckSaveStatusEvent>(_onCheckSaveStatus);
    on<CopyResultEvent>(_onCopyResult);
    on<GeneratePdfEvent>(_onGeneratePdf);
    on<ClearMessagesEvent>(_onClearMessages);
  }

  @override
  Future<void> close() {
    _liveRefreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadLotteryResultDetails(
    LoadLotteryResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    try {
      emit(const LotteryResultDetailsLoading());
      _currentUniqueId = event.uniqueId;
      final result = await _useCase.execute(event.uniqueId);

      // Process lottery numbers
      final allNumbers = _processLotteryNumbers(result.result);

      // Detect newly updated tickets
      final newlyUpdated = _detectNewlyUpdatedTickets(result.result);

      // Check if result is saved
      final isSaved = SavedResultsService.isResultSaved(event.uniqueId);

      // Load matched numbers for default filter
      final matchedNumbers = await _loadMatchedNumbers(result.result);

      // Create loaded state
      final loadedState = LotteryResultDetailsLoaded(
        data: result,
        allLotteryNumbers: allNumbers,
        filteredLotteryNumbers: allNumbers,
        isSaved: isSaved,
        matchedNumbers: matchedNumbers,
        newlyUpdatedTickets: newlyUpdated,
      );

      emit(loadedState);

      // If initial search query provided, perform search
      if (event.initialSearchQuery != null && event.initialSearchQuery!.isNotEmpty) {
        add(SearchQueryChangedEvent(event.initialSearchQuery!));
      }

      // Start live refresh timer if in live hours
      _startLiveRefreshTimer();

      // Store previous result for next comparison
      _previousResult = result.result;
    } catch (e) {
      emit(LotteryResultDetailsError(
          'Failed to load lottery result: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLotteryResultDetails(
    RefreshLotteryResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;

    try {
      // Show refreshing state if currently loaded
      if (currentState is LotteryResultDetailsLoaded) {
        emit(currentState.copyWith(isRefreshing: true, clearMessages: true));
      }

      _currentUniqueId = event.uniqueId;
      final result = await _useCase.execute(event.uniqueId, forceRefresh: true);

      // Process lottery numbers
      final allNumbers = _processLotteryNumbers(result.result);

      // Detect newly updated tickets
      final newlyUpdated = _detectNewlyUpdatedTickets(result.result);

      // Preserve existing state or load new
      final isSaved = currentState is LotteryResultDetailsLoaded
          ? currentState.isSaved
          : SavedResultsService.isResultSaved(event.uniqueId);

      final matchedNumbers = currentState is LotteryResultDetailsLoaded
          ? currentState.matchedNumbers
          : await _loadMatchedNumbers(result.result);

      final patternNumbers = currentState is LotteryResultDetailsLoaded
          ? currentState.patternNumbers
          : <String>{};

      final repeatedNumbers = currentState is LotteryResultDetailsLoaded
          ? currentState.repeatedNumbers
          : <String>{};

      final selectedFilter = currentState is LotteryResultDetailsLoaded
          ? currentState.selectedFilter
          : 'matched';

      // Preserve search query if any
      final searchQuery = currentState is LotteryResultDetailsLoaded
          ? currentState.searchQuery
          : '';

      // Re-apply search if there was one
      final filteredNumbers = searchQuery.isNotEmpty && searchQuery.length >= _minSearchLength
          ? _performSmartSearch(searchQuery, allNumbers)
          : allNumbers;

      emit(LotteryResultDetailsLoaded(
        data: result,
        allLotteryNumbers: allNumbers,
        filteredLotteryNumbers: filteredNumbers,
        searchQuery: searchQuery,
        hasSearchResults: filteredNumbers.isNotEmpty,
        isSaved: isSaved,
        isRefreshing: false,
        selectedFilter: selectedFilter,
        matchedNumbers: matchedNumbers,
        patternNumbers: patternNumbers,
        repeatedNumbers: repeatedNumbers,
        newlyUpdatedTickets: newlyUpdated,
      ));

      // Restart live refresh timer
      _startLiveRefreshTimer();

      // Store previous result for next comparison
      _previousResult = result.result;
    } catch (e) {
      emit(LotteryResultDetailsError(
          'Failed to refresh lottery result: ${e.toString()}'));
    }
  }

  Future<void> _onBackgroundRefreshResultDetails(
    BackgroundRefreshResultDetailsEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    try {
      // Only refresh if we have a current uniqueId
      if (_currentUniqueId != null) {
        final result = await _useCase.execute(_currentUniqueId!, forceRefresh: true);

        // Process lottery numbers
        final allNumbers = _processLotteryNumbers(result.result);

        // Detect newly updated tickets
        final newlyUpdated = _detectNewlyUpdatedTickets(result.result);

        // Re-apply search if there was one
        final filteredNumbers = currentState.searchQuery.isNotEmpty &&
                currentState.searchQuery.length >= _minSearchLength
            ? _performSmartSearch(currentState.searchQuery, allNumbers)
            : allNumbers;

        emit(currentState.copyWith(
          data: result,
          allLotteryNumbers: allNumbers,
          filteredLotteryNumbers: filteredNumbers,
          hasSearchResults: filteredNumbers.isNotEmpty,
          newlyUpdatedTickets: newlyUpdated,
          clearMessages: true,
        ));

        // Store previous result for next comparison
        _previousResult = result.result;
      }
    } catch (e) {
      // Silently fail for background refresh
    }
  }

  void _startLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    
    final now = DateTime.now();
    final isLiveHour = now.hour >= 15 && now.hour < 16;
    
    if (isLiveHour) {
      // During live hours, refresh every 30 seconds
      _liveRefreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) {
          final currentTime = DateTime.now();
          final stillLiveHour = currentTime.hour >= 15 && currentTime.hour < 16;
          
          if (stillLiveHour) {
            add(BackgroundRefreshResultDetailsEvent());
          } else {
            // Stop timer if no longer in live hours
            timer.cancel();
          }
        },
      );
    }
  }

  // Search event handler
  Future<void> _onSearchQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    final query = event.query.trim();

    if (query.isEmpty) {
      // Show all numbers
      emit(currentState.copyWith(
        searchQuery: '',
        filteredLotteryNumbers: currentState.allLotteryNumbers,
        hasSearchResults: true,
        clearMessages: true,
      ));
      return;
    }

    if (query.length < _minSearchLength) {
      // Update query but don't filter yet
      emit(currentState.copyWith(
        searchQuery: query,
        filteredLotteryNumbers: currentState.allLotteryNumbers,
        clearMessages: true,
      ));
      return;
    }

    // Perform smart search
    final results = _performSmartSearch(query, currentState.allLotteryNumbers);

    emit(currentState.copyWith(
      searchQuery: query,
      filteredLotteryNumbers: results,
      hasSearchResults: results.isNotEmpty,
      errorMessage: results.isEmpty ? "No results found for '$query'" : null,
    ));
  }

  // Filter event handler
  Future<void> _onFilterChanged(
    FilterChangedEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    Set<String> matchedNumbers = {};
    Set<String> patternNumbers = {};
    Set<String> repeatedNumbers = {};

    if (event.filterType == 'matched') {
      matchedNumbers = await _loadMatchedNumbers(currentState.data.result);
    } else if (event.filterType == 'patterns') {
      patternNumbers = _analyzePatterns(currentState.data.result);
    } else if (event.filterType == 'repeated') {
      repeatedNumbers = await _loadRepeatedNumbers(currentState.data.result);
    }

    emit(currentState.copyWith(
      selectedFilter: event.filterType,
      matchedNumbers: matchedNumbers,
      patternNumbers: patternNumbers,
      repeatedNumbers: repeatedNumbers,
      clearMessages: true,
    ));
  }

  // Toggle save event handler
  Future<void> _onToggleSaveResult(
    ToggleSaveResultEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    try {
      final result = currentState.data.result;
      final success = currentState.isSaved
          ? await SavedResultsService.removeSavedResult(result.uniqueId)
          : await SavedResultsService.saveLotteryResult(result);

      if (success) {
        emit(currentState.copyWith(
          isSaved: !currentState.isSaved,
          successMessage: currentState.isSaved
              ? 'Removed from saved results'
              : 'Saved to your collection',
        ));
      } else {
        emit(currentState.copyWith(
          errorMessage: 'Failed to save result',
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  // Check save status event handler
  Future<void> _onCheckSaveStatus(
    CheckSaveStatusEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    final isSaved = SavedResultsService.isResultSaved(event.uniqueId);
    emit(currentState.copyWith(isSaved: isSaved, clearMessages: true));
  }

  // Copy result event handler
  Future<void> _onCopyResult(
    CopyResultEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    try {
      // Format result text using the formatter
      final resultText = LotteryResultTextFormatter.format(currentState.data.result);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: resultText));

      emit(currentState.copyWith(
        successMessage: 'Result copied to clipboard',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to copy: ${e.toString()}',
      ));
    }
  }

  // Generate PDF event handler
  Future<void> _onGeneratePdf(
    GeneratePdfEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    emit(currentState.copyWith(isGeneratingPdf: true, clearMessages: true));

    try {
      await PdfService.generateAndShareLotteryResult(currentState.data.result);
      emit(currentState.copyWith(
        isGeneratingPdf: false,
        successMessage: 'PDF generated successfully!',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isGeneratingPdf: false,
        errorMessage: 'Failed to generate PDF: ${e.toString()}',
      ));
    }
  }

  // Clear messages event handler
  void _onClearMessages(
    ClearMessagesEvent event,
    Emitter<LotteryResultDetailsState> emit,
  ) {
    final currentState = state;
    if (currentState is! LotteryResultDetailsLoaded) return;

    emit(currentState.copyWith(clearMessages: true));
  }

  // Helper method to refresh current result
  void refreshCurrentResult() {
    if (_currentUniqueId != null) {
      add(RefreshLotteryResultDetailsEvent(_currentUniqueId!));
    }
  }

  // Helper method to clear cache
  Future<void> clearCache() async {
    if (_currentUniqueId != null) {
      await _useCase.clearCache(_currentUniqueId!);
    }
  }

  // ========== BUSINESS LOGIC METHODS (Moved from Widget) ==========

  /// Process lottery numbers and organize them by prize type
  List<Map<String, dynamic>> _processLotteryNumbers(LotteryResultModel result) {
    final numbers = <Map<String, dynamic>>[];

    // Add 1st prize numbers first
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      _addPrizeNumbers(firstPrize, result, numbers);
    }

    // Add consolation prize numbers second
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      _addPrizeNumbers(consolationPrize, result, numbers);
    }

    // Add remaining prizes (2nd to 10th)
    final remainingPrizes = result.prizes
        .where((prize) =>
            prize.prizeType != '1st' && prize.prizeType != 'consolation')
        .toList();

    // Sort remaining prizes by prize type
    remainingPrizes.sort((a, b) {
      final prizeOrder = [
        '2nd',
        '3rd',
        '4th',
        '5th',
        '6th',
        '7th',
        '8th',
        '9th',
        '10th'
      ];
      final aIndex = prizeOrder.indexOf(a.prizeType);
      final bIndex = prizeOrder.indexOf(b.prizeType);
      return aIndex.compareTo(bIndex);
    });

    for (final prize in remainingPrizes) {
      _addPrizeNumbers(prize, result, numbers);
    }

    return numbers;
  }

  /// Add prize numbers to the list
  void _addPrizeNumbers(
    PrizeModel prize,
    LotteryResultModel result,
    List<Map<String, dynamic>> numbers,
  ) {
    // For prizes with tickets array (individual tickets with locations)
    for (final ticket in prize.ticketsWithLocation) {
      numbers.add({
        'number': ticket.ticketNumber,
        'category': prize.prizeTypeFormatted,
        'prize': prize.formattedPrizeAmount,
        'location': ticket.location ?? '',
      });
    }

    // For prizes with ticket_numbers string (grid format)
    for (final ticketNumber in result.getPrizeTicketNumbers(prize)) {
      // Skip if already added from tickets array
      if (!prize.ticketsWithLocation
          .any((t) => t.ticketNumber == ticketNumber)) {
        numbers.add({
          'number': ticketNumber,
          'category': prize.prizeTypeFormatted,
          'prize': prize.formattedPrizeAmount,
          'location': '',
        });
      }
    }
  }

  /// Detect newly updated tickets for shimmer effect
  Set<String> _detectNewlyUpdatedTickets(LotteryResultModel result) {
    // Only track during live hours
    if (!_isLiveHours(result)) return {};

    // If no previous result, return empty set
    if (_previousResult == null) return {};

    // Get all current ticket numbers
    final currentTickets = <String>{};
    for (final prize in result.prizes) {
      for (final ticket in prize.ticketsWithLocation) {
        currentTickets.add(ticket.ticketNumber);
      }
      for (final ticketNumber in result.getPrizeTicketNumbers(prize)) {
        currentTickets.add(ticketNumber);
      }
    }

    // Get all previous ticket numbers
    final previousTickets = <String>{};
    for (final prize in _previousResult!.prizes) {
      for (final ticket in prize.ticketsWithLocation) {
        previousTickets.add(ticket.ticketNumber);
      }
      for (final ticketNumber in _previousResult!.getPrizeTicketNumbers(prize)) {
        previousTickets.add(ticketNumber);
      }
    }

    // Find newly added tickets
    return currentTickets.difference(previousTickets);
  }

  /// Smart search with fallback logic
  List<Map<String, dynamic>> _performSmartSearch(
    String searchQuery,
    List<Map<String, dynamic>> allNumbers,
  ) {
    final searchLower = searchQuery.toLowerCase();

    // First attempt: Direct search for the full query
    List<Map<String, dynamic>> results = allNumbers.where((item) {
      final ticketNumber = item['number'].toString().toLowerCase();
      return ticketNumber.contains(searchLower);
    }).toList();

    // If no results found and query is longer than 4 digits, try fallback search
    if (results.isEmpty && searchQuery.length > 4) {
      // Extract last 4 digits for fallback search
      final lastFourDigits = searchQuery.substring(searchQuery.length - 4);

      // Only proceed if last 4 digits are all numeric
      if (RegExp(r'^\d{4}$').hasMatch(lastFourDigits)) {
        results = allNumbers.where((item) {
          final ticketNumber = item['number'].toString().toLowerCase();
          return ticketNumber.contains(lastFourDigits.toLowerCase());
        }).toList();
      }
    }

    return results;
  }

  /// Load matched numbers from AI predictions
  Future<Set<String>> _loadMatchedNumbers(LotteryResultModel result) async {
    try {
      // Get predictions for all prize types (5th-9th)
      final List<AiPredictionModel> allPredictions = [];

      for (int prizeType = 5; prizeType <= 9; prizeType++) {
        final prediction =
            await PredictionMatchService.getTodaysPrediction(prizeType);
        if (prediction != null) {
          allPredictions.add(prediction);
        }
      }

      // Compare predictions with lottery results
      final matchedMap =
          PredictionMatchService.compareAllPredictionsWithDetailedResults(
        allPredictions,
        result,
      );

      return matchedMap.keys.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Analyze patterns in the current lottery result
  Set<String> _analyzePatterns(LotteryResultModel result) {
    try {
      // Analyze patterns in the current result
      final patternCounts = PatternAnalysisService.analyzePatterns([result]);

      // Get pattern examples (all numbers belonging to each pattern)
      final patternExamples = PatternAnalysisService.getPatternExamples([result]);

      // Find the most common pattern types (excluding "Regular Numbers")
      final sortedPatterns = patternCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Collect all numbers from the top patterns (excluding "Regular Numbers")
      final Set<String> numbersWithPatterns = {};
      for (final entry in sortedPatterns) {
        if (entry.key != 'Regular Numbers' && entry.value > 0) {
          // Add all examples for this pattern type
          final examples = patternExamples[entry.key];
          if (examples != null) {
            numbersWithPatterns.addAll(examples);
          }
        }
      }

      return numbersWithPatterns;
    } catch (e) {
      return {};
    }
  }

  /// Load repeated numbers from predict cache
  Future<Set<String>> _loadRepeatedNumbers(LotteryResultModel result) async {
    try {
      final cacheService = PredictCacheService();

      // Get repeated numbers from predict cache (last 4 digits patterns)
      final cachedRepeatedNumbers = await cacheService.getRepeatedNumbers();

      if (cachedRepeatedNumbers.isEmpty) {
        return {};
      }

      // Match lottery result numbers with cached repeated numbers
      // We check if the last 4 digits of any lottery number matches any repeated pattern
      final Set<String> matchedTickets = {};

      // Get all ticket numbers from the result
      for (final prize in result.prizes) {
        // Check tickets with location
        for (final ticket in prize.ticketsWithLocation) {
          if (_matchesRepeatedPattern(ticket.ticketNumber, cachedRepeatedNumbers)) {
            matchedTickets.add(ticket.ticketNumber);
          }
        }

        // Check ticket numbers from grid
        for (final ticketNumber in result.getPrizeTicketNumbers(prize)) {
          if (_matchesRepeatedPattern(ticketNumber, cachedRepeatedNumbers)) {
            matchedTickets.add(ticketNumber);
          }
        }
      }

      return matchedTickets;
    } catch (e) {
      return {};
    }
  }

  /// Check if a ticket number's last 4 digits match any repeated pattern
  bool _matchesRepeatedPattern(String ticketNumber, List<String> repeatedPatterns) {
    // Extract last 4 digits from ticket number (remove any prefix letters)
    final digitsOnly = ticketNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length < 4) {
      return false;
    }

    final lastFourDigits = digitsOnly.substring(digitsOnly.length - 4);

    // Check if this last 4 digits matches any repeated pattern
    return repeatedPatterns.contains(lastFourDigits);
  }

  /// Check if it's live hours based on current result
  bool _isLiveHours(LotteryResultModel result) {
    return result.isPublished && !result.reOrder;
  }
}
