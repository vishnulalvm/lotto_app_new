import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';

class LiveVideoApiService {
  Future<LiveVideoResponseModel> getLiveVideos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.liveVideos}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return LiveVideoResponseModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to get live videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting live videos: $e');
    }
  }
}
