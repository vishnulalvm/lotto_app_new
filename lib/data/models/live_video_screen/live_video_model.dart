import 'package:equatable/equatable.dart';

class LiveVideoResponseModel extends Equatable {
  final String message;
  final int count;
  final List<LiveVideoModel> data;

  const LiveVideoResponseModel({
    required this.message,
    required this.count,
    required this.data,
  });

  factory LiveVideoResponseModel.fromJson(Map<String, dynamic> json) {
    return LiveVideoResponseModel(
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => LiveVideoModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [message, count, data];
}

class LiveVideoModel extends Equatable {
  final int id;
  final String lotteryName;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String embedUrl;
  final String date;
  final String description;
  final String status;
  final bool isLiveNow;
  final String createdAt;
  final String updatedAt;

  const LiveVideoModel({
    required this.id,
    required this.lotteryName,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.embedUrl,
    required this.date,
    required this.description,
    required this.status,
    required this.isLiveNow,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveVideoModel.fromJson(Map<String, dynamic> json) {
    return LiveVideoModel(
      id: json['id'] ?? 0,
      lotteryName: json['lottery_name'] ?? '',
      youtubeUrl: json['youtube_url'] ?? '',
      youtubeVideoId: json['youtube_video_id'] ?? '',
      embedUrl: json['embed_url'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      isLiveNow: json['is_live_now'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Helper methods for UI display
  String get formattedTitle => lotteryName;

  String get thumbnail =>
      'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg';

  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'live':
        return isLiveNow ? 'LIVE NOW' : 'SCHEDULED';
      case 'ended':
        return 'ENDED';
      default:
        return status.toUpperCase();
    }
  }

  bool get isLive => status.toLowerCase() == 'live' && isLiveNow;

  String get formattedDescription {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  @override
  List<Object?> get props => [
        id,
        lotteryName,
        youtubeUrl,
        youtubeVideoId,
        embedUrl,
        date,
        description,
        status,
        isLiveNow,
        createdAt,
        updatedAt
      ];
}
