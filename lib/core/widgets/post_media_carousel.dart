import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/timeline_tokens.dart';
import 'timeline/pdf_page_carousel.dart';

/// Médias du post style LinkedIn : image pleine largeur + PDF en pages
/// scrollables horizontalement.
class PostMediaCarousel extends StatelessWidget {
  const PostMediaCarousel({
    super.key,
    this.imageUrl = '',
    this.pdfUrl = '',
    this.pdfPageCount = 0,
    this.onOpenPdf,
    this.height = 260,
  });

  final String imageUrl;
  final String pdfUrl;
  final int pdfPageCount;
  final VoidCallback? onOpenPdf;
  final double height;

  bool get _hasImage => imageUrl.trim().isNotEmpty;
  bool get _hasPdf => pdfUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasImage && !_hasPdf) return const SizedBox.shrink();

    // Photo seule → bloc plein largeur (LinkedIn).
    if (_hasImage && !_hasPdf) {
      return _FullBleedImage(url: imageUrl, height: height);
    }

    // PDF seul → carrousel de pages.
    if (_hasPdf && !_hasImage) {
      return PdfPageCarousel(
        url: pdfUrl,
        pageCount: pdfPageCount,
        onOpen: onOpenPdf,
        height: height,
      );
    }

    // Photo + PDF → défilement horizontal des deux.
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.92,
            child: _FullBleedImage(url: imageUrl, height: height),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.88,
            child: PdfPageCarousel(
              url: pdfUrl,
              pageCount: pdfPageCount,
              onOpen: onOpenPdf,
              height: height,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullBleedImage extends StatelessWidget {
  const _FullBleedImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        placeholder: (_, _) => Container(
          color: const Color(0xFFF3F2EF),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: TimelineTokens.feedBg,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 40, color: TimelineTokens.meta),
              SizedBox(height: 8),
              Text(
                'Image indisponible',
                style: TextStyle(color: TimelineTokens.meta, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
