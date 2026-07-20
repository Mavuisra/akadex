import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PdfControllerPinch? _controller;
  String? _error;
  bool _loading = true;
  bool _showSearch = false;
  int _page = 1;
  int _total = 0;
  final _searchCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final res = await Dio().get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final doc = await PdfDocument.openData(Uint8List.fromList(res.data!));
      if (!mounted) return;
      setState(() {
        _total = doc.pagesCount;
        _controller = PdfControllerPinch(document: Future.value(doc));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d’ouvrir le PDF.';
      });
    }
  }

  Future<void> _downloadExternal() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _goToPage() {
    final n = int.tryParse(_pageCtrl.text.trim());
    if (n == null || _controller == null) return;
    final page = n.clamp(1, _total);
    _controller!.jumpToPage(page);
    setState(() => _page = page);
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    // Navigation par numéro de page si l’utilisateur tape un entier.
    final asPage = int.tryParse(q);
    if (asPage != null && _controller != null) {
      final page = asPage.clamp(1, _total);
      _controller!.jumpToPage(page);
      setState(() => _page = page);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recherche « $q » : ouvre le PDF externe pour une recherche texte complète.',
        ),
        action: SnackBarAction(
          label: 'Ouvrir',
          onPressed: _downloadExternal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F23),
        foregroundColor: Colors.white,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(),
                decoration: const InputDecoration(
                  hintText: 'Page n° ou mot-clé…',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Télécharger / ouvrir',
            onPressed: _downloadExternal,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null || _controller == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error ?? 'Lecteur indisponible',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _downloadExternal,
                          child: const Text('Ouvrir dans le navigateur'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfViewPinch(
                  controller: _controller!,
                  onPageChanged: (page) => setState(() => _page = page),
                ),
      bottomNavigationBar: _controller == null
          ? null
          : SafeArea(
              child: Container(
                color: const Color(0xFF1B1F23),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _page > 1
                          ? () {
                              final p = _page - 1;
                              _controller!.jumpToPage(p);
                              setState(() => _page = p);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        _total > 0 ? 'Page $_page / $_total' : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: _pageCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'N°',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        onSubmitted: (_) => _goToPage(),
                      ),
                    ),
                    IconButton(
                      onPressed: _page < _total
                          ? () {
                              final p = _page + 1;
                              _controller!.jumpToPage(p);
                              setState(() => _page = p);
                            }
                          : null,
                      icon:
                          const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
