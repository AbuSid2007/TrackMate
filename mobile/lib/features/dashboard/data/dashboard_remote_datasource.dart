import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class DashboardRemoteDataSource {
  final Dio dio;
  DashboardRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> getStepsSummary() async {
    try {
      final res = await dio.get(ApiConstants.stepsSummary);
      return res.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> getHydrationSummary() async {
    try {
      final res = await dio.get(ApiConstants.hydrationSummary);
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

  Future<int> getStreak() async {
    try {
      final res = await dio.get(ApiConstants.stepsStreak);
      return (res.data['streak_days'] as num).toInt();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}