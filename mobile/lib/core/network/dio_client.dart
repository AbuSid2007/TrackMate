import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/models/auth_models.dart';

class DioClient {
  static Dio create(TokenStorage tokenStorage) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    dio.interceptors.add(_AuthInterceptor(dio, tokenStorage));
    return dio;
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _storage;

  _AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiConstants.refresh) {
      try {
        final refreshToken = await _storage.getRefresh();
        if (refreshToken == null) return handler.next(err);

        final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final res = await refreshDio.post(
          ApiConstants.refresh,
          data: {'refresh_token': refreshToken},
        );
        final tokens = TokenModel.fromJson(res.data as Map<String, dynamic>);
        await _storage.save(tokens);

        err.requestOptions.headers['Authorization'] =
            'Bearer ${tokens.accessToken}';
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        await _storage.clear();
      }
    }
    handler.next(err);
  }
}