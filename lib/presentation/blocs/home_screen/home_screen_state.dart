import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';

abstract class HomeScreenResultsState {}

class HomeScreenResultsInitial extends HomeScreenResultsState {}

class HomeScreenResultsLoading extends HomeScreenResultsState {}

class HomeScreenResultsLoaded extends HomeScreenResultsState {
  final HomeScreenResultsModel data;
  final DateTime? filteredDate;
  final bool isFiltered;

  HomeScreenResultsLoaded(
    this.data, {
    this.filteredDate,
    this.isFiltered = false,
  });

  @override
  String toString() =>
      'HomeScreenResultsLoaded(count: ${data.count}, isFiltered: $isFiltered, filteredDate: $filteredDate)';
}

class HomeScreenResultsError extends HomeScreenResultsState {
  final String message;

  HomeScreenResultsError(this.message);

  @override
  String toString() => 'HomeScreenResultsError(message: $message)';
}
