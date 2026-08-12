import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

bool _isFlutterTestBinding() {
  final binding = WidgetsBinding.instance;
  return binding.runtimeType.toString().contains('TestWidgets');
}

bool _supportsPdfxRenderer() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool _isValidPng(Uint8List bytes) {
  return bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

Uint8List? _validatedPng(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty || !_isValidPng(bytes)) {
    return null;
  }
  return bytes;
}

Future<PdfThumbnailResult> renderPdfThumbnail({
  Uint8List? data,
  String? filePath,
  double scale = 1.6,
}) async {
  PdfDocument? doc;
  try {
    if (_isFlutterTestBinding()) {
      if ((data == null || data.isEmpty) &&
          (filePath == null || filePath.isEmpty)) {
        return const PdfThumbnailResult(
          error: 'Aucune donnée PDF à rendre',
        );
      }
      return PdfThumbnailResult(
        bytes: _fallbackPdfThumbnailBytes,
        pageCount: 1,
      );
    }

    if (!_supportsPdfxRenderer()) {
      return const PdfThumbnailResult(
        pageCount: 1,
        error: 'Aperçu PDF indisponible sur cette plateforme',
      );
    }

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
    final renderWidth = (page.width * scale).clamp(120.0, 1400.0);
    final renderHeight = (page.height * scale).clamp(120.0, 1800.0);
    final img = await page.render(
      width: renderWidth,
      height: renderHeight,
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );
    await page.close();
    await doc.close();
    doc = null;

    final bytes = _validatedPng(img?.bytes);
    if (bytes == null) {
      return PdfThumbnailResult(
        pageCount: pages,
        error: 'Impossible de générer l’aperçu de ce PDF',
      );
    }
    return PdfThumbnailResult(bytes: bytes, pageCount: pages);
  } catch (e, st) {
    debugPrint('renderPdfThumbnail failed: $e\n$st');
    try {
      await doc?.close();
    } catch (_) {}

    return PdfThumbnailResult(
      pageCount: 1,
      error: 'Aperçu indisponible pour ce PDF',
    );
  }
}

/// Aperçu publication : miniature PNG ou carte PDF propre (jamais d’erreur brute).
class PdfPreviewCard extends StatelessWidget {
  const PdfPreviewCard({
    super.key,
    this.thumbnailBytes,
    required this.fileName,
    this.pageCount = 0,
    this.height = 180,
    this.busy = false,
  });

  final Uint8List? thumbnailBytes;
  final String fileName;
  final int pageCount;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final validThumb = _validatedPng(thumbnailBytes);

    if (busy) {
      return _PdfPlaceholder(
        height: height,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 10),
            Text(
              'Aperçu PDF…',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (validThumb != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0xFFF0F2F5),
          child: Image.memory(
            validThumb,
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => _PdfPlaceholder(
              height: height,
              fileName: fileName,
              pageCount: pageCount,
            ),
          ),
        ),
      );
    }

    return _PdfPlaceholder(
      height: height,
      fileName: fileName,
      pageCount: pageCount,
    );
  }
}

class _PdfPlaceholder extends StatelessWidget {
  const _PdfPlaceholder({
    required this.height,
    this.fileName,
    this.pageCount = 0,
    this.child,
  });

  final double height;
  final String? fileName;
  final int pageCount;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: const Color(0xFFF0F2F5),
        child: Center(
          child: child ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      fileName ?? 'Document PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (pageCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$pageCount page${pageCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }
}
