import 'package:equatable/equatable.dart';

abstract class LiveVideoEvent extends Equatable {
  const LiveVideoEvent();

  @override
  List<Object?> get props => [];
}

class LoadLiveVideosEvent extends LiveVideoEvent {
  const LoadLiveVideosEvent();
}

class RefreshLiveVideosEvent extends LiveVideoEvent {
  const RefreshLiveVideosEvent();
}
