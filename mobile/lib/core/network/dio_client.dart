import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class DioClient {
  static Dio create() {
    final cookieJar = kIsWeb ? null : CookieJar();

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        extra: {'withCredentials': true},
      ),
    );

    if (cookieJar != null) {
      dio.interceptors.add(CookieManager(cookieJar));
    }

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    dio.interceptors.add(_RefreshInterceptor(dio, cookieJar));

    return dio;
  }
}

class _RefreshInterceptor extends Interceptor {
  final Dio _dio;
  late final Dio _refreshDio;

  _RefreshInterceptor(this._dio, CookieJar? cookieJar) {
    _refreshDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));
    if (cookieJar != null) {
      _refreshDio.interceptors.add(CookieManager(cookieJar));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiConstants.refresh) {
      try {
        await _refreshDio.post(ApiConstants.refresh);
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }
}