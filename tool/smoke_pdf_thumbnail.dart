import 'dart:io';
import 'dart:typed_data';

import 'package:akadex/core/utils/pdf_thumbnail.dart';
import 'package:flutter/widgets.dart';

/// Smoke test desktop : génère une miniature PDF réelle via pdfx natif.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pdf = File('tmp_smoke_preview.pdf');
  pdf.writeAsBytesSync(_minimalPdf());
  try {
    final fromData = await renderPdfThumbnail(data: _minimalPdf());
    stdout.writeln(
      'data: hasImage=${fromData.hasImage} pages=${fromData.pageCount} '
      'bytes=${fromData.bytes?.length} err=${fromData.error}',
    );

    final fromFile = await renderPdfThumbnail(filePath: pdf.path);
    stdout.writeln(
      'file: hasImage=${fromFile.hasImage} pages=${fromFile.pageCount} '
      'bytes=${fromFile.bytes?.length} err=${fromFile.error}',
    );

    final ok = fromData.hasImage || fromFile.hasImage;
    if (!ok) {
      stderr.writeln('FAIL: aucune miniature générée');
      exitCode = 1;
      return;
    }
    stdout.writeln('OK: miniature PDF générée');
  } finally {
    if (pdf.existsSync()) pdf.deleteSync();
  }
}

Uint8List _minimalPdf() {
  const raw = '''%PDF-1.4
1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj
2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj
3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources<< /Font<< /F1 5 0 R >> >> >>endobj
4 0 obj<< /Length 44 >>stream
BT /F1 24 Tf 72 720 Td (Akadex Preview) Tj ET
endstream
endobj
5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000274 00000 n 
0000000369 00000 n 
trailer<< /Size 6 /Root 1 0 R >>
startxref
446
%%EOF
''';
  return Uint8List.fromList(raw.codeUnits);
}
