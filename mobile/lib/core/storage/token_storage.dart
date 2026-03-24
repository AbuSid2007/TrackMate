import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/data/models/auth_models.dart';

class TokenStorage {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  final _secure = const FlutterSecureStorage();

  Future<void> save(TokenModel tokens) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_access, tokens.accessToken);
      await prefs.setString(_refresh, tokens.refreshToken);
    } else {
      await _secure.write(key: _access, value: tokens.accessToken);
      await _secure.write(key: _refresh, value: tokens.refreshToken);
    }
  }

  Future<String?> getAccess() async {
    if (kIsWeb) {
      return (await SharedPreferences.getInstance()).getString(_access);
    }
    return _secure.read(key: _access);
  }

  Future<String?> getRefresh() async {
    if (kIsWeb) {
      return (await SharedPreferences.getInstance()).getString(_refresh);
    }
    return _secure.read(key: _refresh);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_access);
      await prefs.remove(_refresh);
    } else {
      await _secure.delete(key: _access);
      await _secure.delete(key: _refresh);
    }
  }
}