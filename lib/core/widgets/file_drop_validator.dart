/// Validation pure pour la zone d’upload (testable hors UI).
class FileDropSelection {
  const FileDropSelection({
    required this.name,
    required this.bytes,
    this.path,
  });

  final String name;
  final List<int> bytes;
  final String? path;

  int get size => bytes.length;
}

class FileDropValidationResult {
  const FileDropValidationResult.ok(this.selection)
      : error = null,
        assert(selection != null);

  const FileDropValidationResult.error(this.error) : selection = null;

  final FileDropSelection? selection;
  final String? error;

  bool get isValid => selection != null && error == null;
}

abstract final class FileDropValidator {
  static const defaultMaxBytes = 20 * 1024 * 1024; // 20 Mo

  /// Extensions autorisées selon le type de leçon professeur.
  static List<String> extensionsForLessonType(String contentType) {
    return switch (contentType) {
      'pdf' => const ['pdf'],
      'slides' => const ['pdf', 'ppt', 'pptx'],
      'tp' || 'td' || 'exercise' => const ['pdf', 'doc', 'docx', 'zip'],
      _ => const ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'],
    };
  }

  /// Extensions pour contributions étudiant (Ma Fac / Bibliothèque).
  static List<String> extensionsForDocumentType(String docType) {
    return switch (docType) {
      'powerpoint' || 'slides' => const ['pdf', 'ppt', 'pptx'],
      'word' => const ['doc', 'docx', 'pdf'],
      'image' => const ['jpg', 'jpeg', 'png', 'webp'],
      'lien' || 'video' => const [],
      _ => const ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'],
    };
  }

  static String extensionOf(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase().trim();
  }

  static FileDropValidationResult validate({
    required String name,
    required List<int> bytes,
    String? path,
    required List<String> allowedExtensions,
    int maxBytes = defaultMaxBytes,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FileDropValidationResult.error('Nom de fichier manquant.');
    }
    if (bytes.isEmpty) {
      return const FileDropValidationResult.error(
        'Le fichier est vide ou illisible.',
      );
    }
    if (bytes.length > maxBytes) {
      final mo = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return FileDropValidationResult.error(
        'Fichier trop volumineux (max $mo Mo).',
      );
    }
    final ext = extensionOf(trimmed);
    final allowed = allowedExtensions
        .map((e) => e.toLowerCase().replaceAll('.', ''))
        .toList();
    if (allowed.isNotEmpty && (ext.isEmpty || !allowed.contains(ext))) {
      final list = allowed.map((e) => '.$e').join(', ');
      return FileDropValidationResult.error(
        'Extension non autorisée. Formats acceptés : $list.',
      );
    }
    return FileDropValidationResult.ok(
      FileDropSelection(name: trimmed, bytes: bytes, path: path),
    );
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
