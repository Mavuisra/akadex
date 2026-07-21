import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show Database, ConflictAlgorithm, openDatabase;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactory, databaseFactoryFfi, sqfliteFfiInit;

import '../../domain/models/document_type.dart';
import '../../domain/models/models.dart';
import '../mappers/mappers.dart';

/// Stockage académique local (SQLite sur mobile/desktop, mémoire sur web).
class LocalAcademicStore {
  LocalAcademicStore._(this._db);

  final Database? _db;
  final Map<String, Map<String, dynamic>> _memCourses = {};
  final Map<String, Map<String, dynamic>> _memDocs = {};
  final Map<String, Map<String, dynamic>> _memUnis = {};
  final Map<String, Map<String, dynamic>> _memProgress = {};
  final List<Map<String, dynamic>> _memPending = [];
  final Map<String, String> _memMeta = {};

  static Future<LocalAcademicStore> open() async {
    if (kIsWeb) {
      return LocalAcademicStore._(null);
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'akadex_offline.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE universities (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            slug TEXT,
            city TEXT,
            country TEXT,
            payload TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE courses (
            id TEXT PRIMARY KEY,
            code TEXT,
            title TEXT,
            teacher TEXT,
            semester TEXT,
            credits INTEGER,
            department TEXT,
            description TEXT,
            university TEXT,
            faculty TEXT,
            document_count INTEGER,
            payload TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            title TEXT,
            doc_type TEXT,
            author TEXT,
            university TEXT,
            department TEXT,
            course TEXT,
            year TEXT,
            downloads INTEGER,
            views INTEGER,
            favorites INTEGER,
            rating REAL,
            description TEXT,
            is_featured INTEGER,
            course_id TEXT,
            payload TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE lesson_progress (
            lesson_id TEXT PRIMARY KEY,
            position_seconds INTEGER,
            completed INTEGER,
            dirty INTEGER,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_ops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return LocalAcademicStore._(db);
  }

  Future<void> close() async => _db?.close();

  // --- Universities ---

  Future<void> upsertUniversities(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().toIso8601String();
    if (_db == null) {
      for (final u in items) {
        _memUnis[u['id'].toString()] = {...u, 'updated_at': now};
      }
      return;
    }
    final batch = _db.batch();
    for (final u in items) {
      batch.insert(
        'universities',
        {
          'id': u['id'].toString(),
          'name': (u['name'] ?? '').toString(),
          'slug': (u['slug'] ?? '').toString(),
          'city': (u['city'] ?? '').toString(),
          'country': (u['country'] ?? '').toString(),
          'payload': jsonEncode(u),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<UniversityItem>> getUniversities() async {
    if (_db == null) {
      return _memUnis.values.map(universityFromJson).toList();
    }
    final rows = await _db.query('universities', orderBy: 'name ASC');
    return rows
        .map((r) => universityFromJson(
              Map<String, dynamic>.from(jsonDecode(r['payload']! as String)),
            ))
        .toList();
  }

  // --- Courses ---

  Future<void> upsertCourses(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().toIso8601String();
    if (_db == null) {
      for (final c in items) {
        _memCourses[c['id'].toString()] = {...c, 'updated_at': now};
      }
      return;
    }
    final batch = _db.batch();
    for (final c in items) {
      final teachers = (c['teacher_names'] as List?) ?? const [];
      batch.insert(
        'courses',
        {
          'id': c['id'].toString(),
          'code': (c['code'] ?? '').toString(),
          'title': (c['title'] ?? '').toString(),
          'teacher': teachers.isEmpty ? '' : teachers.first.toString(),
          'semester': (c['semester'] ?? '').toString(),
          'credits': asInt(c['credits']),
          'department': (c['department_name'] ?? '').toString(),
          'description': (c['description'] ?? '').toString(),
          'university': (c['university_name'] ?? '').toString(),
          'faculty': (c['faculty_name'] ?? '').toString(),
          'document_count': asInt(c['document_count']),
          'payload': jsonEncode(c),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Course>> getCourses({String? semester}) async {
    if (_db == null) {
      var list = _memCourses.values.map(courseFromJson).toList();
      if (semester != null && semester != 'Tous') {
        list = list.where((c) => c.semester == semester).toList();
      }
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    }
    final rows = semester == null || semester == 'Tous'
        ? await _db.query('courses', orderBy: 'code ASC')
        : await _db.query(
            'courses',
            where: 'semester = ?',
            whereArgs: [semester],
            orderBy: 'code ASC',
          );
    return rows
        .map((r) => courseFromJson(
              Map<String, dynamic>.from(jsonDecode(r['payload']! as String)),
            ))
        .toList();
  }

  Future<Course?> getCourse(String id) async {
    if (_db == null) {
      final m = _memCourses[id];
      return m == null ? null : courseFromJson(m);
    }
    final rows = await _db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return courseFromJson(
      Map<String, dynamic>.from(jsonDecode(rows.first['payload']! as String)),
    );
  }

  // --- Documents ---

  Future<void> upsertDocuments(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().toIso8601String();
    if (_db == null) {
      for (final d in items) {
        _memDocs[d['id'].toString()] = {...d, 'updated_at': now};
      }
      return;
    }
    final batch = _db.batch();
    for (final d in items) {
      batch.insert(
        'documents',
        {
          'id': d['id'].toString(),
          'title': (d['title'] ?? '').toString(),
          'doc_type': (d['doc_type'] ?? '').toString(),
          'author': (d['author_name'] ?? '').toString(),
          'university': (d['university_name'] ?? '').toString(),
          'department': (d['department_name'] ?? '').toString(),
          'course': (d['course_title'] ?? d['course_code'] ?? '').toString(),
          'year': (d['academic_year'] ?? '').toString(),
          'downloads': asInt(d['downloads']),
          'views': asInt(d['views']),
          'favorites': asInt(d['favorites_count']),
          'rating': asDouble(d['rating_avg']),
          'description': (d['description'] ?? '').toString(),
          'is_featured': d['is_featured'] == true ? 1 : 0,
          'course_id': d['course']?.toString(),
          'payload': jsonEncode(d),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AcademicDocument>> getDocuments({
    String? search,
    DocumentType? docType,
    String? courseId,
    bool featuredOnly = false,
  }) async {
    Iterable<Map<String, dynamic>> source;
    if (_db == null) {
      source = _memDocs.values;
    } else {
      final rows = await _db.query('documents');
      source = rows.map(
        (r) => Map<String, dynamic>.from(jsonDecode(r['payload']! as String)),
      );
    }

    var maps = source.toList();
    if (featuredOnly) {
      maps = maps.where((d) => d['is_featured'] == true).toList();
    }
    if (courseId != null) {
      maps = maps.where((d) => d['course']?.toString() == courseId).toList();
    }
    var list = maps.map(documentFromJson).toList();
    if (docType != null) {
      list = list.where((d) => d.type == docType).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where(
            (d) =>
                d.title.toLowerCase().contains(q) ||
                d.description.toLowerCase().contains(q) ||
                d.author.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => b.downloads.compareTo(a.downloads));
    return list;
  }

  Future<AcademicDocument?> getDocument(String id) async {
    if (_db == null) {
      final m = _memDocs[id];
      return m == null ? null : documentFromJson(m);
    }
    final rows = await _db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return documentFromJson(
      Map<String, dynamic>.from(jsonDecode(rows.first['payload']! as String)),
    );
  }

  // --- Lesson progress (dirty = à pousser) ---

  Future<void> saveProgressLocal(
    String lessonId, {
    required int positionSeconds,
    bool completed = false,
    bool dirty = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final row = {
      'lesson_id': lessonId,
      'position_seconds': positionSeconds,
      'completed': completed ? 1 : 0,
      'dirty': dirty ? 1 : 0,
      'updated_at': now,
    };
    if (_db == null) {
      _memProgress[lessonId] = row;
      return;
    }
    await _db.insert(
      'lesson_progress',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProgress(String lessonId) async {
    if (_db == null) return _memProgress[lessonId];
    final rows = await _db.query(
      'lesson_progress',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> dirtyProgress() async {
    if (_db == null) {
      return _memProgress.values.where((r) => r['dirty'] == 1).toList();
    }
    return _db.query('lesson_progress', where: 'dirty = 1');
  }

  Future<void> markProgressClean(String lessonId) async {
    if (_db == null) {
      final r = _memProgress[lessonId];
      if (r != null) r['dirty'] = 0;
      return;
    }
    await _db.update(
      'lesson_progress',
      {'dirty': 0},
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  // --- Pending ops ---

  Future<void> enqueueOp(String opType, Map<String, dynamic> payload) async {
    final row = {
      'op_type': opType,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (_db == null) {
      _memPending.add({...row, 'id': _memPending.length + 1});
      return;
    }
    await _db.insert('pending_ops', row);
  }

  Future<List<Map<String, dynamic>>> pendingOps() async {
    if (_db == null) return List.from(_memPending);
    return _db.query('pending_ops', orderBy: 'id ASC');
  }

  Future<void> deletePendingOp(int id) async {
    if (_db == null) {
      _memPending.removeWhere((e) => e['id'] == id);
      return;
    }
    await _db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  // --- Sync meta ---

  Future<void> setMeta(String key, String value) async {
    if (_db == null) {
      _memMeta[key] = value;
      return;
    }
    await _db.insert(
      'sync_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMeta(String key) async {
    if (_db == null) return _memMeta[key];
    final rows = await _db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<int> courseCount() async {
    if (_db == null) return _memCourses.length;
    final r = await _db.rawQuery('SELECT COUNT(*) AS c FROM courses');
    return asInt(r.first['c']);
  }

  Future<int> documentCount() async {
    if (_db == null) return _memDocs.length;
    final r = await _db.rawQuery('SELECT COUNT(*) AS c FROM documents');
    return asInt(r.first['c']);
  }
}
