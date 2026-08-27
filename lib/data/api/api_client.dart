import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

final dioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      // Render free : cold start souvent > 30–50 s.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Un retry sur timeout GET (réveil Render).
        final opts = error.requestOptions;
        final isTimeout = error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout;
        final retries = (opts.extra['akadex_retries'] as int?) ?? 0;
        if (isTimeout &&
            retries < 1 &&
            (opts.method.toUpperCase() == 'GET')) {
          opts.extra['akadex_retries'] = retries + 1;
          try {
            final clone = await dio.fetch(opts);
            return handler.resolve(clone);
          } catch (_) {
            // tombe sur l’erreur originale ci-dessous
          }
        }
        if (error.response?.statusCode == 401) {
          final refresh = prefs.getString('refresh_token');
          if (refresh != null && refresh.isNotEmpty) {
            try {
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: AppConstants.apiBaseUrl,
                  connectTimeout: const Duration(seconds: 60),
                  receiveTimeout: const Duration(seconds: 90),
                ),
              );
              final res = await refreshDio.post(
                'auth/token/refresh/',
                data: {'refresh': refresh},
              );
              final access = res.data['access'] as String?;
              if (access != null) {
                await prefs.setString('access_token', access);
                final req = error.requestOptions;
                req.headers['Authorization'] = 'Bearer $access';
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              }
            } catch (_) {
              await prefs.remove('access_token');
              await prefs.remove('refresh_token');
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

List<Map<String, dynamic>> unwrapList(dynamic data) {
  if (data is Map && data['results'] is List) {
    return (data['results'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return [];
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    if (status != null && status >= 500) {
      return 'Le serveur Akadex est temporairement indisponible '
          '(erreur $status). Réessaie dans une minute.';
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Le serveur met du temps à démarrer (Render). '
          'Réessaie dans quelques secondes.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur. Vérifie ta connexion.';
    }
    return error.message ?? 'Erreur réseau';
  }
  final text = error.toString();
  if (text.contains('took longer than') || text.contains('receiveTimeout')) {
    return 'Le serveur met du temps à démarrer (Render). '
        'Réessaie dans quelques secondes.';
  }
  if (text.contains('status code of 500') || text.contains('500')) {
    return 'Le serveur Akadex est temporairement indisponible. Réessaie bientôt.';
  }
  return text;
}
