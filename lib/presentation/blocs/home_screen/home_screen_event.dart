abstract class HomeScreenResultsEvent {}

class LoadLotteryResultsEvent extends HomeScreenResultsEvent {
  final bool forceRefresh;
  
  LoadLotteryResultsEvent({this.forceRefresh = false});
  
  @override
  String toString() => 'LoadLotteryResultsEvent(forceRefresh: $forceRefresh)';
}

class RefreshLotteryResultsEvent extends HomeScreenResultsEvent {
  @override
  String toString() => 'RefreshLotteryResultsEvent()';
}

class LoadLotteryResultsByDateEvent extends HomeScreenResultsEvent {
  final DateTime selectedDate;
  
  LoadLotteryResultsByDateEvent(this.selectedDate);
  
  @override
  String toString() => 'LoadLotteryResultsByDateEvent(selectedDate: $selectedDate)';
}

class ClearDateFilterEvent extends HomeScreenResultsEvent {
  @override
  String toString() => 'ClearDateFilterEvent()';
}

/// Event for connectivity changes
class ConnectivityChangedEvent extends HomeScreenResultsEvent {
  final bool isOnline;
  
  ConnectivityChangedEvent(this.isOnline);
  
  @override
  String toString() => 'ConnectivityChangedEvent(isOnline: $isOnline)';
}

/// Event to clear cache
class ClearCacheEvent extends HomeScreenResultsEvent {
  @override
  String toString() => 'ClearCacheEvent()';
}

/// Event for background refresh (silent refresh)
class BackgroundRefreshEvent extends HomeScreenResultsEvent {
  @override
  String toString() => 'BackgroundRefreshEvent()';
}