abstract class UserPointsEvent {}

class FetchUserPointsEvent extends UserPointsEvent {
  final String phoneNumber;

  FetchUserPointsEvent({required this.phoneNumber});
}

class RefreshUserPointsEvent extends UserPointsEvent {
  final String phoneNumber;

  RefreshUserPointsEvent({required this.phoneNumber});
}