import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

abstract class LotteryResultDetailsState extends Equatable {
  const LotteryResultDetailsState();

  @override
  List<Object?> get props => [];
}

class LotteryResultDetailsInitial extends LotteryResultDetailsState {
  const LotteryResultDetailsInitial();
}

class LotteryResultDetailsLoading extends LotteryResultDetailsState {
  const LotteryResultDetailsLoading();
}

class LotteryResultDetailsLoaded extends LotteryResultDetailsState {
  final LotteryResultDetailsModel data;

  // Processed lottery numbers
  final List<Map<String, dynamic>> allLotteryNumbers;
  final List<Map<String, dynamic>> filteredLotteryNumbers;

  // Search state
  final String searchQuery;
  final bool hasSearchResults;

  // UI state
  final bool isSaved;
  final bool isGeneratingPdf;
  final bool isRefreshing;

  // Filter state
  final String selectedFilter;
  final Set<String> matchedNumbers;
  final Set<String> patternNumbers;

  // Newly updated tickets (for shimmer effect)
  final Set<String> newlyUpdatedTickets;

  // Side effects (one-time events)
  final String? successMessage;
  final String? errorMessage;

  const LotteryResultDetailsLoaded({
    required this.data,
    required this.allLotteryNumbers,
    this.filteredLotteryNumbers = const [],
    this.searchQuery = '',
    this.hasSearchResults = true,
    this.isSaved = false,
    this.isGeneratingPdf = false,
    this.isRefreshing = false,
    this.selectedFilter = 'matched',
    this.matchedNumbers = const {},
    this.patternNumbers = const {},
    this.newlyUpdatedTickets = const {},
    this.successMessage,
    this.errorMessage,
  });

  LotteryResultDetailsLoaded copyWith({
    LotteryResultDetailsModel? data,
    List<Map<String, dynamic>>? allLotteryNumbers,
    List<Map<String, dynamic>>? filteredLotteryNumbers,
    String? searchQuery,
    bool? hasSearchResults,
    bool? isSaved,
    bool? isGeneratingPdf,
    bool? isRefreshing,
    String? selectedFilter,
    Set<String>? matchedNumbers,
    Set<String>? patternNumbers,
    Set<String>? newlyUpdatedTickets,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return LotteryResultDetailsLoaded(
      data: data ?? this.data,
      allLotteryNumbers: allLotteryNumbers ?? this.allLotteryNumbers,
      filteredLotteryNumbers: filteredLotteryNumbers ?? this.filteredLotteryNumbers,
      searchQuery: searchQuery ?? this.searchQuery,
      hasSearchResults: hasSearchResults ?? this.hasSearchResults,
      isSaved: isSaved ?? this.isSaved,
      isGeneratingPdf: isGeneratingPdf ?? this.isGeneratingPdf,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      matchedNumbers: matchedNumbers ?? this.matchedNumbers,
      patternNumbers: patternNumbers ?? this.patternNumbers,
      newlyUpdatedTickets: newlyUpdatedTickets ?? this.newlyUpdatedTickets,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    data,
    allLotteryNumbers,
    filteredLotteryNumbers,
    searchQuery,
    hasSearchResults,
    isSaved,
    isGeneratingPdf,
    isRefreshing,
    selectedFilter,
    matchedNumbers,
    patternNumbers,
    newlyUpdatedTickets,
    successMessage,
    errorMessage,
  ];

  @override
  String toString() => 'LotteryResultDetailsLoaded(lotteryName: ${data.result.lotteryName}, searchQuery: $searchQuery)';
}

class LotteryResultDetailsError extends LotteryResultDetailsState {
  final String message;

  const LotteryResultDetailsError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'LotteryResultDetailsError(message: $message)';
}
