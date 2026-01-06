import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';

class LiveVideoApiService {
  final Dio _dio;

  LiveVideoApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<LiveVideoResponseModel> getLiveVideos() async {
    try {
      final response = await _dio.get(ApiConstants.liveVideos);
      if (response.statusCode == 200) {
        return LiveVideoResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get live videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting live videos: $e');
    }
  }
}
