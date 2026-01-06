import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_request_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_delete_response_model.dart';

class DuplicatePurchaseException implements Exception {
  final String message;
  DuplicatePurchaseException(this.message);

  @override
  String toString() => message;
}

class LotteryPurchaseApiService {
  final Dio _dio;

  LotteryPurchaseApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<LotteryPurchaseResponseModel> purchaseLottery(
    LotteryPurchaseRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.lotteryPurchase,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return LotteryPurchaseResponseModel.fromJson(response.data);
      } else {
        final errorBody = response.data;

        // Check if it's a duplicate purchase error
        if (response.statusCode == 400 &&
            errorBody['errors'] != null &&
            errorBody['errors']['non_field_errors'] != null) {
          final errors = errorBody['errors']['non_field_errors'] as List;
          if (errors.any((error) => error.toString().contains('must make a unique set'))) {
            throw DuplicatePurchaseException('You have already purchased this lottery number for the selected date');
          }
        }

        // Generic error
        final message = errorBody['message'] ?? 'Failed to purchase lottery';
        throw Exception(message);
      }
    } catch (e) {
      if (e is DuplicatePurchaseException) {
        rethrow;
      }
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<LotteryPurchaseDeleteResponseModel> deleteLotteryPurchase(
    LotteryPurchaseRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.lotteryPurchase,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return LotteryPurchaseDeleteResponseModel.fromJson(response.data);
      } else {
        final errorBody = response.data;

        // Check for specific error responses
        if (response.statusCode == 404) {
          throw Exception('Record not found');
        }

        // Generic error
        final message = errorBody['message'] ?? 'Failed to delete lottery purchase';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}