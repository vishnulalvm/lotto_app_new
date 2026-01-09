import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          // Longer timeouts for slow connections (15 seconds as recommended)
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add dio_smart_retry for automatic retries with exponential backoff
      _instance!.interceptors.add(
        RetryInterceptor(
          dio: _instance!,
          logPrint: print, // Show retry logs
          retries: 3, // Retry up to 3 times
          retryDelays: const [
            Duration(seconds: 1),  // 1st retry after 1 second
            Duration(seconds: 2),  // 2nd retry after 2 seconds
            Duration(seconds: 4),  // 3rd retry after 4 seconds (exponential backoff)
          ],
          retryableExtraStatuses: {408, 502, 503, 504}, // Also retry these HTTP status codes
        ),
      );

      // Add logging interceptor (optional, for debugging)
      _instance!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) {
            // Only log in debug mode
            // print(object);
          },
        ),
      );
    }
    return _instance!;
  }

  // Reset instance (useful for testing or configuration changes)
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }
}
