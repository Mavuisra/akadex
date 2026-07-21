import '../../../domain/models/models.dart';

/// Couvertures Unsplash thématiques (campus, salles, labos, etc.).
abstract final class CourseCoverImages {
  static const _pool = <String>[
    'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200&q=80',
    'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200&q=80',
    'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1200&q=80',
    'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1200&q=80',
    'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=1200&q=80',
    'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&q=80',
    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80',
    'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200&q=80',
    'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=1200&q=80',
    'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=1200&q=80',
  ];

  static const _byKeyword = <String, String>{
    'info':
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    'algo':
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    'python':
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    'ia':
        'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=1200&q=80',
    'droit':
        'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200&q=80',
    'jurid':
        'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200&q=80',
    'méd':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'med':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'santé':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'sante':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1200&q=80',
    'écon':
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80',
    'econ':
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80',
    'gestion':
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80',
    'admin':
        'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1200&q=80',
    'polit':
        'https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=1200&q=80',
    'chimie':
        'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&q=80',
    'phys':
        'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&q=80',
    'math':
        'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=1200&q=80',
    'agro':
        'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=1200&q=80',
    'com':
        'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=1200&q=80',
    'entrepr':
        'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1200&q=80',
  };

  /// Toujours une URL illustrative (cover API ou fallback thématique).
  static String resolve(Course course) {
    final remote = course.coverUrl.trim();
    if (remote.isNotEmpty) return remote;

    final hay = [
      course.code,
      course.title,
      course.faculty,
      course.department,
    ].join(' ').toLowerCase();

    for (final entry in _byKeyword.entries) {
      if (hay.contains(entry.key)) return entry.value;
    }

    return _pool[course.id.hashCode.abs() % _pool.length];
  }
}
