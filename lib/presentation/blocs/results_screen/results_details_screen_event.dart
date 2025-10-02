import 'package:equatable/equatable.dart';

abstract class LotteryResultDetailsEvent extends Equatable {
  const LotteryResultDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLotteryResultDetailsEvent extends LotteryResultDetailsEvent {
  final String uniqueId;
  final String? initialSearchQuery;

  const LoadLotteryResultDetailsEvent(this.uniqueId, {this.initialSearchQuery});

  @override
  List<Object?> get props => [uniqueId, initialSearchQuery];

  @override
  String toString() => 'LoadLotteryResultDetailsEvent(uniqueId: $uniqueId)';
}

class RefreshLotteryResultDetailsEvent extends LotteryResultDetailsEvent {
  final String uniqueId;

  const RefreshLotteryResultDetailsEvent(this.uniqueId);

  @override
  List<Object?> get props => [uniqueId];

  @override
  String toString() => 'RefreshLotteryResultDetailsEvent(uniqueId: $uniqueId)';
}

class BackgroundRefreshResultDetailsEvent extends LotteryResultDetailsEvent {
  const BackgroundRefreshResultDetailsEvent();

  @override
  String toString() => 'BackgroundRefreshResultDetailsEvent()';
}

// Search events
class SearchQueryChangedEvent extends LotteryResultDetailsEvent {
  final String query;

  const SearchQueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];

  @override
  String toString() => 'SearchQueryChangedEvent(query: $query)';
}

// Filter events
class FilterChangedEvent extends LotteryResultDetailsEvent {
  final String filterType;

  const FilterChangedEvent(this.filterType);

  @override
  List<Object?> get props => [filterType];

  @override
  String toString() => 'FilterChangedEvent(filterType: $filterType)';
}

// Save/bookmark events
class ToggleSaveResultEvent extends LotteryResultDetailsEvent {
  const ToggleSaveResultEvent();

  @override
  String toString() => 'ToggleSaveResultEvent()';
}

class CheckSaveStatusEvent extends LotteryResultDetailsEvent {
  final String uniqueId;

  const CheckSaveStatusEvent(this.uniqueId);

  @override
  List<Object?> get props => [uniqueId];

  @override
  String toString() => 'CheckSaveStatusEvent(uniqueId: $uniqueId)';
}

// Copy result events
class CopyResultEvent extends LotteryResultDetailsEvent {
  const CopyResultEvent();

  @override
  String toString() => 'CopyResultEvent()';
}

// PDF generation events
class GeneratePdfEvent extends LotteryResultDetailsEvent {
  const GeneratePdfEvent();

  @override
  String toString() => 'GeneratePdfEvent()';
}

// Clear messages event (for side effects)
class ClearMessagesEvent extends LotteryResultDetailsEvent {
  const ClearMessagesEvent();

  @override
  String toString() => 'ClearMessagesEvent()';
}