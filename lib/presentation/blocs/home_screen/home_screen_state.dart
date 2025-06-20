import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';

abstract class HomeScreenResultsState {}

class HomeScreenResultsInitial extends HomeScreenResultsState {}

class HomeScreenResultsLoading extends HomeScreenResultsState {
  final bool isRefreshing;
  
  HomeScreenResultsLoading({this.isRefreshing = false});
}

class HomeScreenResultsLoaded extends HomeScreenResultsState {
  final HomeScreenResultsModel data;
  final DateTime? filteredDate;
  final bool isFiltered;
  final bool isOffline;
  final DataSource dataSource;
  final int? cacheAgeInMinutes;

  HomeScreenResultsLoaded(
    this.data, {
    this.filteredDate,
    this.isFiltered = false,
    this.isOffline = false,
    this.dataSource = DataSource.network,
    this.cacheAgeInMinutes,
  });

  /// Copy with new properties
  HomeScreenResultsLoaded copyWith({
    HomeScreenResultsModel? data,
    DateTime? filteredDate,
    bool? isFiltered,
    bool? isOffline,
    DataSource? dataSource,
    int? cacheAgeInMinutes,
  }) {
    return HomeScreenResultsLoaded(
      data ?? this.data,
      filteredDate: filteredDate ?? this.filteredDate,
      isFiltered: isFiltered ?? this.isFiltered,
      isOffline: isOffline ?? this.isOffline,
      dataSource: dataSource ?? this.dataSource,
      cacheAgeInMinutes: cacheAgeInMinutes ?? this.cacheAgeInMinutes,
    );
  }

  @override
  String toString() =>
      'HomeScreenResultsLoaded(count: ${data.count}, isFiltered: $isFiltered, filteredDate: $filteredDate, isOffline: $isOffline, dataSource: $dataSource, cacheAge: ${cacheAgeInMinutes}min)';
}

class HomeScreenResultsError extends HomeScreenResultsState {
  final String message;
  final bool hasOfflineData;
  final HomeScreenResultsModel? offlineData;

  HomeScreenResultsError(
    this.message, {
    this.hasOfflineData = false,
    this.offlineData,
  });

  @override
  String toString() => 'HomeScreenResultsError(message: $message, hasOfflineData: $hasOfflineData)';
}

/// State for connectivity changes
class HomeScreenResultsConnectivityChanged extends HomeScreenResultsState {
  final bool isOnline;
  final HomeScreenResultsState previousState;

  HomeScreenResultsConnectivityChanged(this.isOnline, this.previousState);
}
