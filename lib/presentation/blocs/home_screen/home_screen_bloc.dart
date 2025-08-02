import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/home_screen/home_screen_usecase.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';
import 'package:lotto_app/data/services/connectivity_service.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';

class HomeScreenResultsBloc
    extends Bloc<HomeScreenResultsEvent, HomeScreenResultsState> {
  final HomeScreenResultsUseCase _useCase;
  final ConnectivityService _connectivityService;

  // Cache all results to avoid repeated API calls when filtering
  HomeScreenResultsModel? _cachedResults;

  // Connectivity subscription
  StreamSubscription<bool>? _connectivitySubscription;

  HomeScreenResultsBloc(
    this._useCase,
    this._connectivityService,
  ) : super(HomeScreenResultsInitial()) {
    on<LoadLotteryResultsEvent>(_onLoadLotteryResults);
    on<RefreshLotteryResultsEvent>(_onRefreshLotteryResults);
    on<LoadLotteryResultsByDateEvent>(_onLoadLotteryResultsByDate);
    on<ClearDateFilterEvent>(_onClearDateFilter);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);
    on<ClearCacheEvent>(_onClearCache);
    on<BackgroundRefreshEvent>(_onBackgroundRefresh);
    on<BackgroundRefreshCompleteEvent>(_onBackgroundRefreshComplete);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (isOnline) => add(ConnectivityChangedEvent(isOnline)),
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadLotteryResults(
    LoadLotteryResultsEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      emit(HomeScreenResultsLoading());

      final result = await _useCase.execute(
        forceRefresh: event.forceRefresh,
        onBackgroundRefreshComplete: (freshData) {
          // When background refresh completes, update the UI with fresh data
          _handleBackgroundRefreshComplete(freshData);
        },
      );
      _cachedResults = result;

      // Get additional metadata
      final dataSource = await _useCase.getDataSource();
      final cacheInfo = await _useCase.getCacheInfo();

      emit(HomeScreenResultsLoaded(
        result,
        isFiltered: false,
        isOffline: _connectivityService.isOffline,
        dataSource: dataSource,
        cacheAgeInMinutes: cacheInfo['ageInMinutes'],
      ));
    } catch (e) {
      await _handleError(e, emit);
    }
  }

  Future<void> _onRefreshLotteryResults(
    RefreshLotteryResultsEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // Show refreshing state if we already have data
      if (state is HomeScreenResultsLoaded) {
        emit(HomeScreenResultsLoading(isRefreshing: true));
      } else {
        emit(HomeScreenResultsLoading());
      }

      final result = await _useCase.execute(forceRefresh: true);
      _cachedResults = result;

      // Get additional metadata
      final dataSource = await _useCase.getDataSource();
      final cacheInfo = await _useCase.getCacheInfo();

      emit(HomeScreenResultsLoaded(
        result,
        isFiltered: false,
        isOffline: _connectivityService.isOffline,
        dataSource: dataSource,
        cacheAgeInMinutes: cacheInfo['ageInMinutes'],
      ));
    } catch (e) {
      await _handleError(e, emit);
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
      final filteredResults =
          _filterResultsByDate(_cachedResults!, event.selectedDate);

      // Get metadata
      final dataSource = await _useCase.getDataSource();
      final cacheInfo = await _useCase.getCacheInfo();

      emit(HomeScreenResultsLoaded(
        filteredResults,
        filteredDate: event.selectedDate,
        isFiltered: true,
        isOffline: _connectivityService.isOffline,
        dataSource: dataSource,
        cacheAgeInMinutes: cacheInfo['ageInMinutes'],
      ));
    } catch (e) {
      await _handleError(e, emit, context: 'Failed to filter results');
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

      // Get metadata
      final dataSource = await _useCase.getDataSource();
      final cacheInfo = await _useCase.getCacheInfo();

      // Show all results without filter
      emit(HomeScreenResultsLoaded(
        _cachedResults!,
        isFiltered: false,
        isOffline: _connectivityService.isOffline,
        dataSource: dataSource,
        cacheAgeInMinutes: cacheInfo['ageInMinutes'],
      ));
    } catch (e) {
      await _handleError(e, emit, context: 'Failed to clear filter');
    }
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(
    ConnectivityChangedEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    if (state is HomeScreenResultsLoaded) {
      final currentState = state as HomeScreenResultsLoaded;

      // Update the offline status in current state
      emit(currentState.copyWith(isOffline: !event.isOnline));

      // If we just came back online and have stale data, refresh
      if (event.isOnline && currentState.dataSource == DataSource.cache) {
        add(RefreshLotteryResultsEvent());
      }
    }
  }

  /// Clear cache
  Future<void> _onClearCache(
    ClearCacheEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      await _useCase.clearCache();
      _cachedResults = null;

      // Reload data
      add(LoadLotteryResultsEvent(forceRefresh: true));
    } catch (e) {
      await _handleError(e, emit, context: 'Failed to clear cache');
    }
  }

  /// Background refresh - silently update data without showing loading state
  Future<void> _onBackgroundRefresh(
    BackgroundRefreshEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // Only perform background refresh if we're not in loading state
      if (state is HomeScreenResultsLoading) {
        return;
      }

      final result = await _useCase.execute(forceRefresh: true);
      _cachedResults = result;

      // Get additional metadata
      final dataSource = await _useCase.getDataSource();
      final cacheInfo = await _useCase.getCacheInfo();

      // If we have a current loaded state, preserve the filter settings
      if (state is HomeScreenResultsLoaded) {
        final currentState = state as HomeScreenResultsLoaded;
        
        // If filtered, apply the same filter to new data
        HomeScreenResultsModel dataToEmit = result;
        if (currentState.isFiltered && currentState.filteredDate != null) {
          dataToEmit = _filterResultsByDate(result, currentState.filteredDate!);
        }

        emit(HomeScreenResultsLoaded(
          dataToEmit,
          filteredDate: currentState.filteredDate,
          isFiltered: currentState.isFiltered,
          isOffline: _connectivityService.isOffline,
          dataSource: dataSource,
          cacheAgeInMinutes: cacheInfo['ageInMinutes'],
        ));
      } else {
        // No previous state, emit normally
        emit(HomeScreenResultsLoaded(
          result,
          isFiltered: false,
          isOffline: _connectivityService.isOffline,
          dataSource: dataSource,
          cacheAgeInMinutes: cacheInfo['ageInMinutes'],
        ));
      }
    } catch (e) {
      // For background refresh, we don't want to show errors unless there's no data
      if (state is! HomeScreenResultsLoaded) {
        await _handleError(e, emit, context: 'Background refresh failed');
      }
      // If we already have loaded data, silently fail the background refresh
    }
  }

  /// Handle background refresh completion from repository callback
  void _handleBackgroundRefreshComplete(HomeScreenResultsModel freshData) {
    // Only update if we're still in a loaded state and the BLoC is not closed
    if (!isClosed && state is HomeScreenResultsLoaded) {
      _cachedResults = freshData;
      
      // Add a background refresh event to update the UI
      add(BackgroundRefreshCompleteEvent(freshData));
    }
  }

  /// Handle background refresh complete event
  Future<void> _onBackgroundRefreshComplete(
    BackgroundRefreshCompleteEvent event,
    Emitter<HomeScreenResultsState> emit,
  ) async {
    try {
      // Only update if we're currently in a loaded state
      if (state is HomeScreenResultsLoaded) {
        final currentState = state as HomeScreenResultsLoaded;
        
        // Update cached results
        _cachedResults = event.freshData;

        // Get updated metadata
        final dataSource = await _useCase.getDataSource();
        final cacheInfo = await _useCase.getCacheInfo();
        
        // If filtered, apply the same filter to new data
        HomeScreenResultsModel dataToEmit = event.freshData;
        if (currentState.isFiltered && currentState.filteredDate != null) {
          dataToEmit = _filterResultsByDate(event.freshData, currentState.filteredDate!);
        }

        // Emit new state with fresh data
        emit(HomeScreenResultsLoaded(
          dataToEmit,
          filteredDate: currentState.filteredDate,
          isFiltered: currentState.isFiltered,
          isOffline: _connectivityService.isOffline,
          dataSource: dataSource,
          cacheAgeInMinutes: cacheInfo['ageInMinutes'],
        ));
      }
    } catch (e) {
      // Silent fail for background refresh completion
    }
  }

  /// Centralized error handling
  Future<void> _handleError(
    dynamic error,
    Emitter<HomeScreenResultsState> emit, {
    String? context,
  }) async {
    final message = context != null ? '$context: $error' : error.toString();

    // Try to get offline data if available
    try {
      final cachedData = await _useCase.execute();
      if (cachedData.results.isNotEmpty) {
        emit(HomeScreenResultsError(
          message,
          hasOfflineData: true,
          offlineData: cachedData,
        ));
        return;
      }
    } catch (_) {
      // Ignore cache errors
    }

    emit(HomeScreenResultsError(message));
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
        // If date parsing fails, exclude this result from filtered results
        return false;
      }
    }).toList();

    // Return new model with filtered results
    return HomeScreenResultsModel(
      status: allResults.status,
      count: filteredResults.length,
      results: filteredResults,
      totalPoints: allResults.totalPoints,
      updates: allResults.updates,
    );
  }

  // Helper method to parse date from result model

  // Helper method to compare dates ignoring time
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

}
