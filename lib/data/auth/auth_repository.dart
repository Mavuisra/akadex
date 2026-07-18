import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';
import '../api/api_client.dart';
import '../mappers/mappers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(sharedPreferencesProvider));
});

final authStateProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserProfile?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  bool get hasToken => (_prefs.getString('access_token') ?? '').isNotEmpty;

  Future<UserProfile> login(String email, String password) async {
    final res = await _dio.post(
      'auth/token/',
      data: {'email': email.trim(), 'password': password},
    );
    final access = res.data['access'] as String;
    final refresh = res.data['refresh'] as String;
    await _prefs.setString('access_token', access);
    await _prefs.setString('refresh_token', refresh);
    final userJson = Map<String, dynamic>.from(res.data['user'] as Map);
    return userFromJson(userJson);
  }

  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    String lastName = '',
  }) async {
    await _dio.post(
      'auth/register/',
      data: {
        'email': email.trim(),
        'username': username.trim(),
        'password': password,
        'password_confirm': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      },
    );
    return login(email, password);
  }

  Future<UserProfile?> me() async {
    if (!hasToken) return null;
    final res = await _dio.get('auth/me/');
    return userFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
  }
}

class AuthController extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthController(this._repo) : super(const AsyncValue.data(null)) {
    restore();
  }

  final AuthRepository _repo;

  Future<void> restore() async {
    if (!_repo.hasToken) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.me);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.register(
        email: email,
        username: username,
        password: password,
        firstName: firstName,
      ),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
