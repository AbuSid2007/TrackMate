import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class WorkoutRemoteDataSource {
  final Dio dio;
  WorkoutRemoteDataSource(this.dio);

  Future<List<dynamic>> searchExercises({String q = ''}) async {
    try {
      final res = await dio.get(ApiConstants.exercises, queryParameters: {'q': q});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> startSession({String? name}) async {
    try {
      final res = await dio.post(ApiConstants.workoutSessions, data: {'name': name});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> finishSession(
      String sessionId, {String? notes, double? caloriesBurned}) async {
    try {
      final res = await dio.put(
        '${ApiConstants.workoutSessions}/$sessionId/finish',
        data: {'notes': notes, 'calories_burned': caloriesBurned},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> logSet(
      String sessionId, Map<String, dynamic> data) async {
    try {
      final res = await dio.post(
        '${ApiConstants.workoutSessions}/$sessionId/sets',
        data: data,
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteSet(String setId) async {
    try {
      await dio.delete('${ApiConstants.workoutSets}/$setId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getSessionHistory({int limit = 20}) async {
    try {
      final res = await dio.get(ApiConstants.workoutSessions,
          queryParameters: {'limit': limit});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}