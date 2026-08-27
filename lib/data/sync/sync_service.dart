import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../local/local_academic_store.dart';
import '../mappers/mappers.dart';

enum SyncStatus { idle, syncing, online, offline, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message = '',
    this.localCourses = 0,
    this.localDocuments = 0,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String message;
  final int localCourses;
  final int localDocuments;

  bool get isOfflineVisible =>
      status == SyncStatus.offline || status == SyncStatus.error;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
    int? localCourses,
    int? localDocuments,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
      localCourses: localCourses ?? this.localCourses,
      localDocuments: localDocuments ?? this.localDocuments,
    );
  }
}

final localStoreProvider = Provider<LocalAcademicStore>((ref) {
  throw UnimplementedError('Override localStoreProvider in main()');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dioProvider), ref.watch(localStoreProvider));
});

final syncStateProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  final controller = SyncController(
    ref.watch(syncServiceProvider),
    ref.watch(localStoreProvider),
  );
  controller.startConnectivityWatch();
  return controller;
});

class SyncController extends StateNotifier<SyncState> {
  SyncController(this._sync, this._store) : super(const SyncState()) {
    refreshCounts();
  }

  final SyncService _sync;
  final LocalAcademicStore _store;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  void startConnectivityWatch() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        _wasOffline = true;
        if (state.status != SyncStatus.syncing) {
          state = state.copyWith(
            status: SyncStatus.offline,
            message: 'Hors ligne — données locales utilisées',
          );
        }
        return;
      }
      // Retour réseau → resync automatique.
      if (_wasOffline || state.status == SyncStatus.offline) {
        _wasOffline = false;
        unawaited(syncNow(force: true));
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> refreshCounts() async {
    final courses = await _store.courseCount();
    final docs = await _store.documentCount();
    final last = await _store.getMeta('last_synced_at');
    state = state.copyWith(
      localCourses: courses,
      localDocuments: docs,
      lastSyncedAt: last == null ? null : DateTime.tryParse(last),
    );
  }

  Future<void> syncNow({bool force = false}) async {
    if (state.status == SyncStatus.syncing) return;
    state = state.copyWith(status: SyncStatus.syncing, message: 'Synchronisation…');
    try {
      final online = await _sync.isOnline();
      if (!online) {
        _wasOffline = true;
        state = state.copyWith(
          status: SyncStatus.offline,
          message: 'Hors ligne — données locales utilisées',
        );
        await refreshCounts();
        return;
      }
      await _sync.pullAndPush();
      await refreshCounts();
      _wasOffline = false;
      state = state.copyWith(
        status: SyncStatus.online,
        lastSyncedAt: DateTime.now(),
        message: 'À jour',
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync partielle — cache local conservé',
      );
      await refreshCounts();
    }
  }
}

class SyncService {
  SyncService(this._dio, this._store);

  final Dio _dio;
  final LocalAcademicStore _store;

  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasNetwork = result.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) return false;
      // Ping léger de l’API
      await _dio.get(
        'universities/',
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> pullAndPush() async {
    await _pushPending();
    await _pullCatalog();
    await _store.setMeta('last_synced_at', DateTime.now().toIso8601String());
  }

  Future<void> _pullCatalog() async {
    final uniRes = await _dio.get('universities/');
    await _store.upsertUniversities(unwrapList(uniRes.data));

    final courses = <Map<String, dynamic>>[];
    var url = 'courses/?ordering=code';
    while (true) {
      final res = await _dio.get(url);
      courses.addAll(unwrapList(res.data));
      final next = res.data is Map ? res.data['next'] : null;
      if (next == null) break;
      final nextStr = next.toString();
      final uri = Uri.parse(nextStr);
      url = uri.path.contains('/api/')
          ? nextStr.split('/api/').last
          : 'courses/?${uri.query}';
      if (courses.length > 2000) break;
    }
    await _store.upsertCourses(courses);

    final docs = <Map<String, dynamic>>[];
    for (final q in [
      'documents/?ordering=-downloads',
      'documents/?is_featured=true',
    ]) {
      final res = await _dio.get(q);
      docs.addAll(unwrapList(res.data));
    }
    final byId = <String, Map<String, dynamic>>{};
    for (final d in docs) {
      byId[d['id'].toString()] = d;
    }
    await _store.upsertDocuments(byId.values.toList());
  }

  Future<void> _pushPending() async {
    // Progression leçons
    final dirty = await _store.dirtyProgress();
    for (final row in dirty) {
      final lessonId = row['lesson_id'].toString();
      try {
        await _dio.post(
          'course-lessons/$lessonId/progress/',
          data: {
            'position_seconds': row['position_seconds'] ?? 0,
            'completed': (row['completed'] == 1 || row['completed'] == true),
          },
        );
        await _store.markProgressClean(lessonId);
      } catch (e) {
        debugPrint('Push progress failed $lessonId: $e');
      }
    }

    // Ops génériques (commentaires, etc.)
    final ops = await _store.pendingOps();
    for (final op in ops) {
      final id = asInt(op['id']);
      final type = op['op_type']?.toString() ?? '';
      final payload = Map<String, dynamic>.from(
        jsonDecode(op['payload'] as String) as Map,
      );
      try {
        if (type == 'course_comment') {
          await _dio.post('course-comments/', data: payload);
        }
        await _store.deletePendingOp(id);
      } catch (e) {
        debugPrint('Push op $type failed: $e');
      }
    }
  }
}
