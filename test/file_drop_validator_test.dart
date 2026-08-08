import 'package:akadex/core/widgets/file_drop_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileDropValidator.extensionsForLessonType', () {
    test('pdf → pdf uniquement', () {
      expect(FileDropValidator.extensionsForLessonType('pdf'), ['pdf']);
    });

    test('slides → pdf ppt pptx', () {
      expect(
        FileDropValidator.extensionsForLessonType('slides'),
        ['pdf', 'ppt', 'pptx'],
      );
    });

    test('tp / td / exercise → docs + zip', () {
      expect(
        FileDropValidator.extensionsForLessonType('tp'),
        ['pdf', 'doc', 'docx', 'zip'],
      );
      expect(
        FileDropValidator.extensionsForLessonType('td'),
        ['pdf', 'doc', 'docx', 'zip'],
      );
    });
  });

  group('FileDropValidator.validate', () {
    test('accepte un PDF valide', () {
      final result = FileDropValidator.validate(
        name: 'cours.pdf',
        bytes: List.filled(200, 1),
        allowedExtensions: const ['pdf'],
      );
      expect(result.isValid, isTrue);
      expect(result.selection!.name, 'cours.pdf');
      expect(result.error, isNull);
    });

    test('refuse extension non autorisée', () {
      final result = FileDropValidator.validate(
        name: 'virus.exe',
        bytes: List.filled(50, 1),
        allowedExtensions: const ['pdf'],
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('Extension non autorisée'));
    });

    test('refuse fichier vide', () {
      final result = FileDropValidator.validate(
        name: 'vide.pdf',
        bytes: const [],
        allowedExtensions: const ['pdf'],
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('vide'));
    });

    test('refuse fichier trop volumineux', () {
      final result = FileDropValidator.validate(
        name: 'gros.pdf',
        bytes: List.filled(100, 1),
        allowedExtensions: const ['pdf'],
        maxBytes: 50,
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('trop volumineux'));
    });

    test('refuse nom manquant', () {
      final result = FileDropValidator.validate(
        name: '   ',
        bytes: List.filled(10, 1),
        allowedExtensions: const ['pdf'],
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('Nom'));
    });
  });

  group('FileDropValidator.formatSize', () {
    test('formate octets / Ko / Mo', () {
      expect(FileDropValidator.formatSize(500), '500 o');
      expect(FileDropValidator.formatSize(2048), '2 Ko');
      expect(FileDropValidator.formatSize(2 * 1024 * 1024), '2.0 Mo');
    });
  });

  group('FileDropValidator.extensionsForDocumentType', () {
    test('support générique → pdf docs zip', () {
      expect(
        FileDropValidator.extensionsForDocumentType('tp'),
        ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'],
      );
    });

    test('lien / vidéo → aucune extension fichier', () {
      expect(FileDropValidator.extensionsForDocumentType('lien'), isEmpty);
      expect(FileDropValidator.extensionsForDocumentType('video'), isEmpty);
    });
  });

  group('FileDropValidator.extensionOf', () {
    test('extrait l’extension en minuscules', () {
      expect(FileDropValidator.extensionOf('Cours.PDF'), 'pdf');
      expect(FileDropValidator.extensionOf('sans'), '');
    });
  });
}
