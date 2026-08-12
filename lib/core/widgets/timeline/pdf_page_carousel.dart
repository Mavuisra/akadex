import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../theme/akadex_theme.dart';
import '../../theme/timeline_tokens.dart';
import '../../utils/pdf_thumbnail.dart';

/// Aperçu PDF style LinkedIn : pages en défilement horizontal.
///
/// Passe [url] (réseau) et/ou [bytes] (fichier local avant publication).
class PdfPageCarousel extends StatefulWidget {
  const PdfPageCarousel({
    super.key,
    this.url = '',
    this.bytes,
    this.pageCount = 0,
    this.onOpen,
    this.height = 220,
    this.onPagesResolved,
  });

  final String url;
  final Uint8List? bytes;
  final int pageCount;
  final VoidCallback? onOpen;
  final double height;
  /// Appelé une fois le nombre de pages connu (utile à la publication).
  final ValueChanged<int>? onPagesResolved;

  @override
  State<PdfPageCarousel> createState() => _PdfPageCarouselState();
}

class _PdfPageCarouselState extends State<PdfPageCarousel> {
  final _pageCtrl = PageController(viewportFraction: 0.88);
  int _index = 0;
  int _pages = 0;
  bool _loading = true;
  String? _error;
  final List<Uint8List> _previews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PdfPageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bytesChanged = oldWidget.bytes != widget.bytes;
    final urlChanged = oldWidget.url != widget.url;
    if (bytesChanged || urlChanged) {
      _load();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _previews.clear();
    });
    try {
      late final Uint8List data;
      final local = widget.bytes;
      if (local != null && local.isNotEmpty) {
        data = local;
      } else if (widget.url.trim().isNotEmpty) {
        final res = await Dio().get<List<int>>(
          widget.url,
          options: Options(responseType: ResponseType.bytes),
        );
        data = Uint8List.fromList(res.data!);
      } else {
        throw StateError('Aucun PDF à prévisualiser');
      }

      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final doc = await PdfDocument.openData(data);
        final total = doc.pagesCount;
        final limit = total.clamp(1, 6);
        final rendered = <Uint8List>[];
        for (var i = 1; i <= limit; i++) {
          final page = await doc.getPage(i);
          final renderWidth = (page.width * 1.2).clamp(120.0, 1400.0);
          final renderHeight = (page.height * 1.2).clamp(120.0, 1800.0);
          final img = await page.render(
            width: renderWidth,
            height: renderHeight,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          await page.close();
          final bytes = img?.bytes;
          if (bytes != null &&
              bytes.length >= 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50) {
            rendered.add(bytes);
          }
        }
        await doc.close();
        if (!mounted) return;
        final resolved = widget.pageCount > 0 ? widget.pageCount : total;
        setState(() {
          _pages = resolved;
          _previews.addAll(rendered);
          _loading = false;
          if (rendered.isEmpty) {
            _error = 'Aperçu indisponible';
          }
        });
        widget.onPagesResolved?.call(resolved);
        return;
      }

      final thumb = await renderPdfThumbnail(data: data);
      if (!mounted) return;
      final resolved =
          widget.pageCount > 0 ? widget.pageCount : thumb.pageCount;
      setState(() {
        _pages = resolved;
        if (thumb.bytes != null && thumb.bytes!.isNotEmpty) {
          _previews.add(thumb.bytes!);
        }
        _loading = false;
        if (_previews.isEmpty) {
          _error = thumb.error ?? 'Aperçu indisponible';
        }
      });
      widget.onPagesResolved?.call(resolved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Aperçu indisponible';
        _pages = widget.pageCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: Material(
            color: const Color(0xFFF3F2EF),
            child: InkWell(
              onTap: widget.onOpen,
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _previews.isEmpty
                      ? _FallbackPreview(
                          pageCount: _pages,
                          error: _error,
                          onOpen: widget.onOpen,
                        )
                      : PageView.builder(
                          controller: _pageCtrl,
                          itemCount: _previews.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _previews[i],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => _FallbackPreview(
                                      pageCount: _pages,
                                      error: 'Aperçu indisponible',
                                      onOpen: widget.onOpen,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  size: 18, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Text(
                _pages > 0
                    ? 'PDF · ${_index + 1}/${_previews.isEmpty ? _pages : _previews.length}'
                        '${_pages > _previews.length && _previews.isNotEmpty ? ' · $_pages pages' : ''}'
                    : 'Document PDF',
                style: TextStyle(
                  fontSize: TimelineTokens.metaSize,
                  color: TimelineTokens.of(context).meta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onOpen,
                child: const Text('Ouvrir'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({
    required this.pageCount,
    this.error,
    this.onOpen,
  });

  final int pageCount;
  final String? error;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded,
              size: 48, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            error ?? 'Document PDF',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AkadexColors.ink,
            ),
          ),
          if (pageCount > 0)
            Text(
              '$pageCount pages',
              style: TextStyle(color: TimelineTokens.of(context).meta),
            ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onOpen,
            child: const Text('Voir le document'),
          ),
        ],
      ),
    );
  }
}
