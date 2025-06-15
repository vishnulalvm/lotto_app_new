
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/home_screen/home_screen_usecase.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';

class HomeScreenResultsBloc
    extends Bloc<HomeScreenResultsEvent, HomeScreenResultsState> {
  final HomeScreenResultsUseCase _useCase;
  
  // Cache all results to avoid repeated API calls when filtering
  HomeScreenResultsModel? _cachedResults;

  HomeScreenResultsBloc(this._useCase) : super(HomeScreenResultsInitial()) {
    on<LoadLotteryResultsEvent>(_onLoadLotteryResults);
    on<RefreshLotteryResultsEvent>(_onRefreshLotteryResults);
    on<LoadLotteryResultsByDateEvent>(_onLoadLotteryResultsByDate);
    on<ClearDateFilterEvent>(_onClearDateFilter);
  }

  Future<void> _onLoadLotteryResults(
    LoadLotteryResultsEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      emit(HomeScreenResultsLoading());
      final result = await _useCase.execute();
      _cachedResults = result; // Cache the results
      emit(HomeScreenResultsLoaded(result, isFiltered: false));
    } catch (e) {
      emit(HomeScreenResultsError(e.toString()));
    }
  }

  Future<void> _onRefreshLotteryResults(
    RefreshLotteryResultsEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // Don't show loading for refresh, but clear any existing filters
      final result = await _useCase.execute();
      _cachedResults = result; // Update cache
      emit(HomeScreenResultsLoaded(result, isFiltered: false));
    } catch (e) {
      emit(HomeScreenResultsError(e.toString()));
    }
  }

  Future<void> _onLoadLotteryResultsByDate(
    LoadLotteryResultsByDateEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // If we don't have cached results, load them first
      if (_cachedResults == null) {
        emit(HomeScreenResultsLoading());
        _cachedResults = await _useCase.execute();
      }

      // Filter results by the selected date
      final filteredResults = _filterResultsByDate(_cachedResults!, event.selectedDate);
      
      emit(HomeScreenResultsLoaded(
        filteredResults,
        filteredDate: event.selectedDate,
        isFiltered: true,
      ));
    } catch (e) {
      emit(HomeScreenResultsError('Failed to filter results: ${e.toString()}'));
    }
  }

  Future<void> _onClearDateFilter(
    ClearDateFilterEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // If we don't have cached results, load them
      if (_cachedResults == null) {
        emit(HomeScreenResultsLoading());
        _cachedResults = await _useCase.execute();
      }

      // Show all results without filter
      emit(HomeScreenResultsLoaded(_cachedResults!, isFiltered: false));
    } catch (e) {
      emit(HomeScreenResultsError('Failed to clear filter: ${e.toString()}'));
    }
  }

  // Helper method to filter results by date
  HomeScreenResultsModel _filterResultsByDate(
    HomeScreenResultsModel allResults,
    DateTime selectedDate,
  ) {
    // Filter results that match the selected date
    final filteredResults = allResults.results.where((result) {
      try {
        // Use the existing dateTime getter from HomeScreenResultModel
        final resultDate = result.dateTime;
        
        // Compare only the date part (year, month, day)
        return _isSameDay(resultDate, selectedDate);
      } catch (e) {
        // Log the error for debugging
        print('Error parsing date for result ${result.id}: ${result.date} - Error: $e');
        // If date parsing fails, exclude this result from filtered results
        return false;
      }
    }).toList();

    // Return new model with filtered results
    return HomeScreenResultsModel(
      status: allResults.status,
      count: filteredResults.length,
      results: filteredResults,
    );
  }

  // Helper method to parse date from result model

  // Helper method to compare dates ignoring time
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Debug method to print all available dates (useful for testing)
  void debugPrintAvailableDates() {
    if (_cachedResults != null) {
      print('Available lottery result dates:');
      for (var result in _cachedResults!.results) {
        try {
          final date = result.dateTime;
          print('- ${result.lotteryName}: ${date.toString()} (${result.formattedDate})');
        } catch (e) {
          print('- ${result.lotteryName}: Error parsing date ${result.date}');
        }
      }
    }
  }
}