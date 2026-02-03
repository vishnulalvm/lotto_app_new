import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';

abstract class HomeScreenResultsEvent extends Equatable {
  const HomeScreenResultsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLotteryResultsEvent extends HomeScreenResultsEvent {
  final bool forceRefresh;

  const LoadLotteryResultsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];

  @override
  String toString() => 'LoadLotteryResultsEvent(forceRefresh: $forceRefresh)';
}

class RefreshLotteryResultsEvent extends HomeScreenResultsEvent {
  const RefreshLotteryResultsEvent();

  @override
  String toString() => 'RefreshLotteryResultsEvent()';
}

class LoadLotteryResultsByDateEvent extends HomeScreenResultsEvent {
  final DateTime selectedDate;

  const LoadLotteryResultsByDateEvent(this.selectedDate);

  @override
  List<Object?> get props => [selectedDate];

  @override
  String toString() =>
      'LoadLotteryResultsByDateEvent(selectedDate: $selectedDate)';
}

class ClearDateFilterEvent extends HomeScreenResultsEvent {
  const ClearDateFilterEvent();

  @override
  String toString() => 'ClearDateFilterEvent()';
}

/// Event for connectivity changes
class ConnectivityChangedEvent extends HomeScreenResultsEvent {
  final bool isOnline;

  const ConnectivityChangedEvent(this.isOnline);

  @override
  List<Object?> get props => [isOnline];

  @override
  String toString() => 'ConnectivityChangedEvent(isOnline: $isOnline)';
}

/// Event to clear cache
class ClearCacheEvent extends HomeScreenResultsEvent {
  const ClearCacheEvent();

  @override
  String toString() => 'ClearCacheEvent()';
}

/// Event for background refresh (silent refresh)
class BackgroundRefreshEvent extends HomeScreenResultsEvent {
  const BackgroundRefreshEvent();

  @override
  String toString() => 'BackgroundRefreshEvent()';
}

/// Event triggered when background refresh completes with fresh data
class BackgroundRefreshCompleteEvent extends HomeScreenResultsEvent {
  final HomeScreenResultsModel freshData;

  const BackgroundRefreshCompleteEvent(this.freshData);

  @override
  List<Object?> get props => [freshData];

  @override
  String toString() =>
      'BackgroundRefreshCompleteEvent(count: ${freshData.count})';
}

/// Event for app lifecycle changes
class AppLifecycleChangedEvent extends HomeScreenResultsEvent {
  final bool isResumed;

  const AppLifecycleChangedEvent({required this.isResumed});

  @override
  List<Object?> get props => [isResumed];

  @override
  String toString() => 'AppLifecycleChangedEvent(isResumed: $isResumed)';
}

/// Event to start periodic refresh timer
class StartPeriodicRefreshEvent extends HomeScreenResultsEvent {
  const StartPeriodicRefreshEvent();

  @override
  String toString() => 'StartPeriodicRefreshEvent()';
}

/// Event to stop periodic refresh timer
class StopPeriodicRefreshEvent extends HomeScreenResultsEvent {
  const StopPeriodicRefreshEvent();

  @override
  String toString() => 'StopPeriodicRefreshEvent()';
}
