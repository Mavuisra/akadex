import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// Génère une miniature PNG de la 1ʳᵉ page d’un PDF.
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

final Uint8List _fallbackPdfThumbnailBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0x00, 0x01, 0x01, 0x01, 0x01, 0x00,
  0x18, 0xDD, 0x8D, 0xB8, 0x00, 0x00, 0x00, 0x00,
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<PdfThumbnailResult> renderPdfThumbnail({
  Uint8List? data,
  String? filePath,
  double scale = 1.6,
}) async {
  PdfDocument? doc;
  try {
    final supportsNativePdfRender =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (data != null && data.isNotEmpty) {
      // Les runners CI / desktop n’ont pas toujours le moteur PDF natif
      // attaché à la plate-forme. On retourne un fallback sûr plutôt que de
      // laisser le plugin exploser avec MissingPluginException.
      if (kIsWeb || !supportsNativePdfRender) {
        return PdfThumbnailResult(
          bytes: _fallbackPdfThumbnailBytes,
          pageCount: 1,
          error: 'Aperçu PDF indisponible sur cette plateforme',
        );
      }

      doc = await PdfDocument.openData(data);
    } else if (filePath != null &&
        filePath.isNotEmpty &&
        !kIsWeb) {
      if (!supportsNativePdfRender) {
        return PdfThumbnailResult(
          bytes: _fallbackPdfThumbnailBytes,
          pageCount: 1,
          error: 'Aperçu PDF indisponible sur cette plateforme',
        );
      }
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

    return PdfThumbnailResult(
      bytes: _fallbackPdfThumbnailBytes,
      pageCount: 1,
      error: e.toString(),
    );
  }
}
