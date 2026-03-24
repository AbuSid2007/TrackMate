import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';

class SocialRemoteDataSource {
  final Dio dio;
  SocialRemoteDataSource(this.dio);

  Future<List<dynamic>> getFeed() async {
    try {
      final res = await dio.get(ApiConstants.feed);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getFriends() async {
    try {
      final res = await dio.get(ApiConstants.friends);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getFriendRequests() async {
    try {
      final res = await dio.get(ApiConstants.friendRequests);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await dio.post('${ApiConstants.friends}/request/$userId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    try {
      await dio.put('${ApiConstants.friends}/request/$requestId',
          data: {'request_id': requestId, 'accept': accept});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await dio.delete('${ApiConstants.friends}/$friendId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> createPost(String content) async {
    try {
      await dio.post(ApiConstants.posts, data: {'content': content});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await dio.delete('${ApiConstants.posts}/$postId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<bool> toggleLike(String postId) async {
    try {
      final res = await dio.post('${ApiConstants.posts}/$postId/like');
      return (res.data as Map<String, dynamic>)['liked'] as bool;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final res = await dio.get(ApiConstants.leaderboard);
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<dynamic>> searchUsers(String q) async {
    try {
      final res = await dio.get(ApiConstants.userSearch,
          queryParameters: {'q': q});
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}