abstract class HomeScreenResultsEvent {}

class LoadLotteryResultsEvent extends HomeScreenResultsEvent {}

class RefreshLotteryResultsEvent extends HomeScreenResultsEvent {}

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