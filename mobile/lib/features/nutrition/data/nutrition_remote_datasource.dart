import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class NutritionRemoteDataSource {
  final Dio dio;
  NutritionRemoteDataSource(this.dio);

  Future<List<dynamic>> searchFoods(String query, {int page = 1}) async {
    try {
      final res = await dio.get(ApiConstants.foodSearch,
          queryParameters: {'q': query, 'page': page});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  Future<Map<String, dynamic>> getHydrationSummary() async {
    try {
      final res = await dio.get(ApiConstants.hydrationSummary);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) { throw mapDioError(e); }
  }

  Future<void> logWater(int amountMl) async {
    try {
      await dio.post(ApiConstants.hydration, data: {'amount_ml': amountMl});
    } on DioException catch (e) { throw mapDioError(e); }
  }
  Future<Map<String, dynamic>> getNutritionSummary({String? date}) async {
    try {
      final res = await dio.get(ApiConstants.nutritionSummary,
          queryParameters: date != null ? {'date': date} : null);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getMeals({String? date}) async {
    try {
      final res = await dio.get(ApiConstants.meals,
          queryParameters: date != null ? {'date': date} : null);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logMeal(Map<String, dynamic> data) async {
    try {
      await dio.post(ApiConstants.meals, data: data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    try {
      await dio.delete('${ApiConstants.meals}/$mealId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}