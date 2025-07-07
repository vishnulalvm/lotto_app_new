import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';
import 'package:lotto_app/data/repositories/live_video_screen/live_video_repository.dart';

class LiveVideoUseCase {
  final LiveVideoRepository _repository;

  LiveVideoUseCase(this._repository);

  Future<List<LiveVideoModel>> execute() async {
    return await _repository.getLiveVideos();
  }
}