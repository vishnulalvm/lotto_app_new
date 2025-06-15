abstract class LotteryResultDetailsEvent {}

class LoadLotteryResultDetailsEvent extends LotteryResultDetailsEvent {
  final String uniqueId;
  
  LoadLotteryResultDetailsEvent(this.uniqueId);
  
  @override
  String toString() => 'LoadLotteryResultDetailsEvent(uniqueId: $uniqueId)';
}

class RefreshLotteryResultDetailsEvent extends LotteryResultDetailsEvent {
  final String uniqueId;
  
  RefreshLotteryResultDetailsEvent(this.uniqueId);
  
  @override
  String toString() => 'RefreshLotteryResultDetailsEvent(uniqueId: $uniqueId)';
}