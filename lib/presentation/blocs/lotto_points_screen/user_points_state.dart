import 'package:lotto_app/data/models/lotto_points_screen/user_points_model.dart';

abstract class UserPointsState {}

class UserPointsInitial extends UserPointsState {}

class UserPointsLoading extends UserPointsState {}

class UserPointsLoaded extends UserPointsState {
  final UserPointsModel userPoints;

  UserPointsLoaded({required this.userPoints});
}

class UserPointsError extends UserPointsState {
  final String message;

  UserPointsError({required this.message});
}

class UserPointsRefreshing extends UserPointsState {
  final UserPointsModel userPoints;

  UserPointsRefreshing({required this.userPoints});
}