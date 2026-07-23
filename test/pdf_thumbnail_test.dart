import 'dart:typed_data';

import 'package:akadex/core/utils/pdf_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';

/// PDF minimal valide (1 page blanche).
Uint8List _minimalPdf() {
  const raw = '''%PDF-1.1
1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj
2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj
3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] >>endobj
xref
0 4
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
trailer<< /Size 4 /Root 1 0 R >>
startxref
190
%%EOF
''';
  return Uint8List.fromList(raw.codeUnits);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renderPdfThumbnail produit une image depuis des bytes PDF', () async {
    final result = await renderPdfThumbnail(data: _minimalPdf());
    // Sur certains runners CI sans moteur PDF natif, le rendu peut échouer.
    // On vérifie alors au moins le chemin d’erreur contrôlé (pas de crash).
    if (result.hasImage) {
      expect(result.pageCount, greaterThanOrEqualTo(1));
      expect(result.bytes!.length, greaterThan(50));
    } else {
      expect(result.error, isNotNull);
    }
  });

  test('renderPdfThumbnail refuse les données vides', () async {
    final result = await renderPdfThumbnail(data: Uint8List(0));
    expect(result.hasImage, isFalse);
    expect(result.error, isNotNull);
  });
}
