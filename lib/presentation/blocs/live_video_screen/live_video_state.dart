import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';

abstract class LiveVideoState {}

class LiveVideoInitial extends LiveVideoState {}

class LiveVideoLoading extends LiveVideoState {
  final bool isRefreshing;
  
  LiveVideoLoading({this.isRefreshing = false});
}

class LiveVideoLoaded extends LiveVideoState {
  final List<LiveVideoModel> videos;
  
  LiveVideoLoaded(this.videos);
}

class LiveVideoError extends LiveVideoState {
  final String message;
  
  LiveVideoError(this.message);
}