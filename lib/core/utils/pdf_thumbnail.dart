import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// Génère une miniature JPEG/PNG de la 1ʳᵉ page d’un PDF.
class PdfThumbnailResult {
  const PdfThumbnailResult({
    this.bytes,
    this.pageCount = 0,
    this.error,
  });

  final Uint8List? bytes;
  final int pageCount;
  final String? error;

  bool get hasImage => bytes != null && bytes!.isNotEmpty;
}

Future<PdfThumbnailResult> renderPdfThumbnail({
  Uint8List? data,
  String? filePath,
  double scale = 1.6,
}) async {
  PdfDocument? doc;
  try {
    if (data != null && data.isNotEmpty) {
      doc = await PdfDocument.openData(data);
    } else if (filePath != null &&
        filePath.isNotEmpty &&
        !kIsWeb) {
      doc = await PdfDocument.openFile(filePath);
    } else {
      return const PdfThumbnailResult(
        error: 'Aucune donnée PDF à rendre',
      );
    }

    final pages = doc.pagesCount;
    if (pages < 1) {
      await doc.close();
      return const PdfThumbnailResult(error: 'PDF vide');
    }

    final page = await doc.getPage(1);
    // PNG : supporté partout (dont Chrome / pdfx web). JPEG non supporté sur web.
    final img = await page.render(
      width: page.width * scale,
      height: page.height * scale,
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );
    await page.close();
    await doc.close();
    doc = null;

    final bytes = img?.bytes;
    if (bytes == null || bytes.isEmpty) {
      return PdfThumbnailResult(
        pageCount: pages,
        error: 'Rendu PDF vide',
      );
    }
    return PdfThumbnailResult(bytes: bytes, pageCount: pages);
  } catch (e, st) {
    debugPrint('renderPdfThumbnail failed: $e\n$st');
    try {
      await doc?.close();
    } catch (_) {}
    return PdfThumbnailResult(error: e.toString());
  }
}
