import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    String postnom = '',
    String phone = '',
    String role = 'student',
    String gender = '',
    String? birthDate,
    String matricule = '',
    String? university,
    String? faculty,
    String? department,
    String? promotion,
    String professionalDomain = '',
    String company = '',
    int? graduationYear,
    String headline = '',
    String bio = '',
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
        'postnom': postnom.trim(),
        'phone': phone.trim(),
        'role': role,
        if (gender.isNotEmpty) 'gender': gender,
        if (birthDate != null && birthDate.isNotEmpty) 'birth_date': birthDate,
        if (matricule.isNotEmpty) 'matricule': matricule.trim(),
        if (university != null && university.isNotEmpty)
          'university': int.tryParse(university) ?? university,
        if (faculty != null && faculty.isNotEmpty)
          'faculty': int.tryParse(faculty) ?? faculty,
        if (department != null && department.isNotEmpty)
          'department': int.tryParse(department) ?? department,
        if (promotion != null && promotion.isNotEmpty)
          'promotion': int.tryParse(promotion) ?? promotion,
        if (professionalDomain.isNotEmpty)
          'professional_domain': professionalDomain.trim(),
        if (company.isNotEmpty) 'company': company.trim(),
        'graduation_year': ?graduationYear,
        if (headline.isNotEmpty) 'headline': headline.trim(),
        if (bio.isNotEmpty) 'bio': bio.trim(),
      },
    );
    return login(email, password);
  }

  Future<UserProfile?> me() async {
    if (!hasToken) return null;
    final res = await _dio.get('auth/me/');
    return userFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Demande un code de reset. Retourne éventuellement `dev_code` (DEBUG serveur).
  Future<String?> requestPasswordReset(String email) async {
    final res = await _dio.post(
      'auth/password-reset/',
      data: {'email': email.trim()},
    );
    final data = res.data;
    if (data is Map && data['dev_code'] != null) {
      return data['dev_code'].toString();
    }
    return null;
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    await _dio.post(
      'auth/password-reset/confirm/',
      data: {
        'email': email.trim(),
        'token': token.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );
  }

  Future<UserProfile> confirmEmail(String token) async {
    final res = await _dio.post(
      'auth/me/confirm-email/',
      data: {'token': token.trim()},
    );
    return userFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// PATCH `auth/me/`. Si `avatar` / `cover` sont fournis (chemin, [XFile],
  /// ou bytes), envoie un [FormData] multipart ; sinon JSON.
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final avatar = payload.remove('avatar');
    final cover = payload.remove('cover');
    final hasFiles = avatar != null || cover != null;

    if (hasFiles) {
      final formMap = <String, dynamic>{};
      for (final e in payload.entries) {
        if (e.value == null) continue;
        formMap[e.key] = e.value is bool || e.value is num
            ? e.value
            : e.value.toString();
      }
      final form = FormData.fromMap(formMap);
      if (avatar != null) {
        form.files.add(
          MapEntry('avatar', await _toMultipart(avatar, 'avatar.jpg')),
        );
      }
      if (cover != null) {
        form.files.add(
          MapEntry('cover', await _toMultipart(cover, 'cover.jpg')),
        );
      }
      final res = await _dio.patch('auth/me/', data: form);
      return userFromJson(Map<String, dynamic>.from(res.data as Map));
    }

    payload.removeWhere((_, v) => v == null);
    final res = await _dio.patch('auth/me/', data: payload);
    return userFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<MultipartFile> _toMultipart(dynamic value, String fallbackName) async {
    if (value is MultipartFile) return value;
    if (value is XFile) {
      final name = value.name.isNotEmpty ? value.name : fallbackName;
      if (kIsWeb || value.path.isEmpty) {
        final bytes = await value.readAsBytes();
        return MultipartFile.fromBytes(bytes, filename: name);
      }
      return MultipartFile.fromFile(value.path, filename: name);
    }
    if (value is Uint8List || value is List<int>) {
      final bytes = value is Uint8List ? value : Uint8List.fromList(value);
      return MultipartFile.fromBytes(bytes, filename: fallbackName);
    }
    final path = value.toString();
    if (kIsWeb) {
      throw ArgumentError(
        'Sur le web, passez un XFile ou des bytes pour $fallbackName',
      );
    }
    final filename = path.split(RegExp(r'[\\/]')).last;
    return MultipartFile.fromFile(
      path,
      filename: filename.isEmpty ? fallbackName : filename,
    );
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final res = await _dio.get('auth/notifications/');
    return unwrapList(res.data).map(notificationFromJson).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.post('auth/notifications/$id/mark_read/');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('auth/notifications/mark_all_read/');
  }

  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
  }

  /// Suppression de compte (API) puis nettoyage local des jetons.
  Future<void> deleteAccount() async {
    await _dio.delete('auth/me/');
    await logout();
  }
}

class AuthController extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthController(this._repo)
      : super(
          _repo.hasToken
              ? const AsyncValue.loading()
              : const AsyncValue.data(null),
        ) {
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
    String lastName = '',
    String postnom = '',
    String phone = '',
    String role = 'student',
    String gender = '',
    String? birthDate,
    String matricule = '',
    String? university,
    String? faculty,
    String? department,
    String? promotion,
    String professionalDomain = '',
    String company = '',
    int? graduationYear,
    String headline = '',
    String bio = '',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.register(
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        postnom: postnom,
        phone: phone,
        role: role,
        gender: gender,
        birthDate: birthDate,
        matricule: matricule,
        university: university,
        faculty: faculty,
        department: department,
        promotion: promotion,
        professionalDomain: professionalDomain,
        company: company,
        graduationYear: graduationYear,
        headline: headline,
        bio: bio,
      ),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = await _repo.updateProfile(data);
    state = AsyncValue.data(user);
  }

  Future<void> confirmEmail(String token) async {
    final user = await _repo.confirmEmail(token);
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
