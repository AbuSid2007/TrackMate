import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class AnalyticsRemoteDataSource {
  final Dio dio;
  AnalyticsRemoteDataSource(this.dio);

  Future<List<dynamic>> getStepsHistory({int days = 7}) async {
    try {
      final res = await dio.get(ApiConstants.stepsHistory,
          queryParameters: {'days': days});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getNutritionSummary() async {
    try {
      final res = await dio.get(ApiConstants.nutritionSummary);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final res = await dio.get(ApiConstants.weeklyStats);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getWeightTrend({int days = 30}) async {
    try {
      final res = await dio.get(ApiConstants.weightTrend,
          queryParameters: {'days': days});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}