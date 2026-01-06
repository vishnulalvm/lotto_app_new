import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add retry interceptor for network errors
      _instance!.interceptors.add(
        InterceptorsWrapper(
          onError: (DioException error, ErrorInterceptorHandler handler) async {
            if (_shouldRetry(error)) {
              try {
                // Retry the request
                final response = await _instance!.fetch(error.requestOptions);
                handler.resolve(response);
              } catch (e) {
                handler.next(error);
              }
            } else {
              handler.next(error);
            }
          },
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

  // Determine if we should retry the request
  static bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  // Reset instance (useful for testing or configuration changes)
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }
}
