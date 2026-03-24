import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class NotificationsRemoteDataSource {
  final Dio dio;
  NotificationsRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> getNotifications(
      {bool unreadOnly = false}) async {
    try {
      final res = await dio.get(ApiConstants.notifications,
          queryParameters: {'unread_only': unreadOnly});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await dio.put('${ApiConstants.notifications}/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await dio.put('${ApiConstants.notifications}/read-all');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await dio.delete('${ApiConstants.notifications}/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}