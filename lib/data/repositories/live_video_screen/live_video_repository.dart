import 'package:lotto_app/data/datasource/api/live_video_screen/live_video_api_service.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';

abstract class LiveVideoRepository {
  Future<List<LiveVideoModel>> getLiveVideos();
}

class LiveVideoRepositoryImpl implements LiveVideoRepository {
  final LiveVideoApiService _apiService;

  LiveVideoRepositoryImpl(this._apiService);

  @override
  Future<List<LiveVideoModel>> getLiveVideos() async {
    try {
      final response = await _apiService.getLiveVideos();
      return response.data;
    } catch (e) {
      throw Exception('Failed to get live videos: $e');
    }
  }
}