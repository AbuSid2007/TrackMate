import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class TrainerRemoteDataSource {
  final Dio dio;
  TrainerRemoteDataSource(this.dio);

  Future<List<dynamic>> getStudents() async {
    try {
      final res = await dio.get(ApiConstants.trainerStudents);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStudentDetail(String id) async {
    try {
      final res = await dio.get('${ApiConstants.trainerStudents}/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getStudentWorkouts(String id) async {
    try {
      final res = await dio.get('${ApiConstants.trainerStudents}/$id/workouts');
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStudentNutrition(String id) async {
    try {
      final res = await dio.get('${ApiConstants.trainerStudents}/$id/nutrition');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStudentStats(String id) async {
    try {
      final res = await dio.get('${ApiConstants.trainerStudents}/$id/stats');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> addNote(String traineeId, String content) async {
    try {
      await dio.post('${ApiConstants.trainerStudents}/$traineeId/notes',
          data: {'content': content});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await dio.get(ApiConstants.trainerStats);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getRequests() async {
    try {
      final res = await dio.get(ApiConstants.trainerRequests);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    try {
      await dio.put('${ApiConstants.trainerRequests}/$requestId',
          data: {'accept': accept});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getCalendar() async {
    try {
      final res = await dio.get(ApiConstants.trainerCalendar);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> scheduleSession(
      String traineeId, String scheduledAt, int durationMinutes,
      {String? notes}) async {
    try {
      await dio.post(ApiConstants.trainerCalendarSessions, data: {
        'trainee_id': traineeId,
        'scheduled_at': scheduledAt,
        'duration_minutes': durationMinutes,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getAvailableTrainers() async {
    try {
      final res = await dio.get(ApiConstants.trainerAvailable);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> sendTrainerRequest(String trainerId, String goal) async {
    try {
      await dio.post(ApiConstants.trainerRequest,
          data: {'trainer_id': trainerId, 'goal': goal});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}