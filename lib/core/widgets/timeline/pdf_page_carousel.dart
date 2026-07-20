import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../theme/akadex_theme.dart';
import '../../theme/timeline_tokens.dart';

/// Aperçu PDF style LinkedIn : pages en défilement horizontal.
class PdfPageCarousel extends StatefulWidget {
  const PdfPageCarousel({
    super.key,
    required this.url,
    this.pageCount = 0,
    this.onOpen,
    this.height = 220,
  });

  final String url;
  final int pageCount;
  final VoidCallback? onOpen;
  final double height;

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
    if (oldWidget.url != widget.url) {
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
      final res = await Dio().get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final doc = await PdfDocument.openData(Uint8List.fromList(res.data!));
      final total = doc.pagesCount;
      final limit = total.clamp(1, 6);
      final rendered = <Uint8List>[];
      for (var i = 1; i <= limit; i++) {
        final page = await doc.getPage(i);
        final img = await page.render(
          width: page.width * 1.2,
          height: page.height * 1.2,
          format: PdfPageImageFormat.jpeg,
        );
        await page.close();
        if (img?.bytes != null) rendered.add(img!.bytes);
      }
      await doc.close();
      if (!mounted) return;
      setState(() {
        _pages = widget.pageCount > 0 ? widget.pageCount : total;
        _previews.addAll(rendered);
        _loading = false;
      });
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
                  color: TimelineTokens.meta,
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
              style: TextStyle(color: TimelineTokens.meta),
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
