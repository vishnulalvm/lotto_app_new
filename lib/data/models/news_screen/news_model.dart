class NewsResponseModel {
  final String status;
  final int code;
  final String message;
  final List<NewsModel> data;

  NewsResponseModel({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    return NewsResponseModel(
      status: json['status'] ?? '',
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => NewsModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'code': code,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class NewsModel {
  final int id;
  final String headline;
  final String content;
  final String imageUrl;
  final String newsUrl;
  final String source;
  final DateTime publishedAt;

  NewsModel({
    required this.id,
    required this.headline,
    required this.content,
    required this.imageUrl,
    required this.newsUrl,
    required this.source,
    required this.publishedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      headline: json['headline'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ?? '',
      newsUrl: json['news_url'] ?? '',
      source: json['source'] ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'content': content,
      'image_url': imageUrl,
      'news_url': newsUrl,
      'source': source,
      'published_at': publishedAt.toIso8601String(),
    };
  }

  // Helper methods for UI
  String get shortContent {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  String get formattedPublishedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    return '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
  }

  bool get hasValidImage {
    return imageUrl.isNotEmpty && Uri.tryParse(imageUrl) != null;
  }

  bool get hasValidNewsUrl {
    return newsUrl.isNotEmpty && Uri.tryParse(newsUrl) != null;
  }
}