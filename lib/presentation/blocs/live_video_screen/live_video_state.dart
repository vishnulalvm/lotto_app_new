import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';

abstract class LiveVideoState extends Equatable {
  const LiveVideoState();

  @override
  List<Object?> get props => [];
}

class LiveVideoInitial extends LiveVideoState {
  const LiveVideoInitial();
}

class LiveVideoLoading extends LiveVideoState {
  final bool isRefreshing;

  const LiveVideoLoading({this.isRefreshing = false});

  @override
  List<Object?> get props => [isRefreshing];
}

class LiveVideoLoaded extends LiveVideoState {
  final List<LiveVideoModel> videos;

  const LiveVideoLoaded(this.videos);

  @override
  List<Object?> get props => [videos];
}

class LiveVideoError extends LiveVideoState {
  final String message;

  const LiveVideoError(this.message);

  @override
  List<Object?> get props => [message];
}
