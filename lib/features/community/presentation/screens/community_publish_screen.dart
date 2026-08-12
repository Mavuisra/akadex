import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/theme/status_backgrounds.dart';
import '../../../../core/utils/pdf_thumbnail.dart';
import '../../../../core/widgets/academic_autocomplete.dart';
import '../../../../core/widgets/post_academic_tags.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

/// Écran « Nouvelle publication » / « Modifier la publication ».
class CommunityPublishScreen extends ConsumerStatefulWidget {
  const CommunityPublishScreen({super.key, this.editingPost});

  final CommunityPost? editingPost;

  @override
  ConsumerState<CommunityPublishScreen> createState() =>
      _CommunityPublishScreenState();
}

class _CommunityPublishScreenState
    extends ConsumerState<CommunityPublishScreen> {
  final _content = TextEditingController();
  final _scrollController = ScrollController();
  final _mediaSectionKey = GlobalKey();

  String _kind = 'discussion';
  bool _loading = false;
  bool _mediaBusy = false;
  double _mediaProgress = 0;
  String _mediaBusyLabel = '';
  String? _bgColor;

  String? _pdfPath;
  String? _pdfName;
  Uint8List? _pdfBytes;
  Uint8List? _pdfThumbBytes;
  int _pdfPageCount = 0;

  String? _imagePath;
  String? _imageName;
  Uint8List? _imageBytes;

  String? _universityId;
  String? _universityName;
  String? _facultyId;
  String? _facultyName;
  String? _promotionId;
  String? _promotionName;

  /// Limite UX + upload : 3 Mo pour PDF et images.
  static const int _maxMediaBytes = 3 * 1024 * 1024;

  static const _kinds = [
    ('discussion', 'Publication', Icons.edit_outlined),
    ('exam', 'Examen', Icons.assignment_turned_in_outlined),
    ('tp', 'TP / TD', Icons.science_outlined),
    ('summary', 'Résumé', Icons.menu_book_outlined),
    ('notes', 'Notes', Icons.notes_rounded),
    ('support', 'Support', Icons.description_outlined),
    ('rapport', 'Rapport de stage', Icons.work_outline_rounded),
    ('projet_tutore', 'Projet tuteuré', Icons.handyman_outlined),
    ('tfc', 'TFC', Icons.school_outlined),
    ('memoire', 'Mémoire', Icons.menu_book_rounded),
    ('question', 'Question', Icons.help_outline_rounded),
  ];

  static const _academicPdfKinds = {
    'exam',
    'tp',
    'summary',
    'notes',
    'support',
    'rapport',
    'projet_tutore',
    'tfc',
    'memoire',
  };

  bool get _isEditing => widget.editingPost != null;

  bool get _hasExistingPdf =>
      !_clearedExistingPdf && (widget.editingPost?.hasPdf ?? false);

  bool get _hasExistingImage =>
      !_clearedExistingImage && (widget.editingPost?.hasImage ?? false);

  bool _clearedExistingPdf = false;
  bool _clearedExistingImage = false;

  bool get _hasPdf =>
      (_pdfBytes != null && _pdfBytes!.isNotEmpty) ||
      (_pdfPath != null && _pdfPath!.isNotEmpty) ||
      _hasExistingPdf;

  bool get _hasImage =>
      (_imageBytes != null && _imageBytes!.isNotEmpty) ||
      (_imagePath != null && _imagePath!.isNotEmpty) ||
      _hasExistingImage;

  bool get _hasMedia => _hasPdf || _hasImage;

  bool get _needsPdf => _academicPdfKinds.contains(_kind);

  bool get _canUseBg =>
      !_hasMedia && StatusBackgrounds.isShortEnough(_content.text);

  String? get _publishBlockedReason {
    if (_loading || _mediaBusy) return 'Chargement en cours…';
    if (_universityName?.trim().isEmpty ?? true) {
      return 'Indique l’université.';
    }
    if (_facultyName?.trim().isEmpty ?? true) {
      return 'Indique la faculté.';
    }
    if (_promotionName?.trim().isEmpty ?? true) {
      return 'Indique la promotion.';
    }
    if (_needsPdf && !_hasPdf) {
      return 'Pour $_kindLabel, appuie sur PDF et choisis un fichier (max 3 Mo).';
    }
    if (_content.text.trim().isEmpty && !_hasMedia) {
      return 'Écris un texte ou ajoute une image / un PDF.';
    }
    return null;
  }

  String get _kindLabel => switch (_kind) {
        'exam' => 'un examen',
        'tp' => 'un TP',
        'summary' => 'un résumé',
        'notes' => 'des notes',
        'support' => 'un support',
        'rapport' => 'un rapport',
        'projet_tutore' => 'un projet tuteuré',
        'tfc' => 'un TFC',
        'memoire' => 'un mémoire',
        _ => 'cette publication',
      };

  bool get _canPublish => _publishBlockedReason == null;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  bool _exceedsLimit(int bytes, {required String label}) {
    if (bytes <= _maxMediaBytes) return false;
    _toast(
      '$label trop volumineux (${_formatMb(bytes)} Mo). '
      'Maximum : 3 Mo.',
    );
    return true;
  }

  static String _formatMb(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1);

  Future<void> _pickPdf() async {
    if (_loading || _mediaBusy) return;
    setState(() {
      _mediaBusy = true;
      _mediaProgress = 0.08;
      _mediaBusyLabel = 'Sélection du PDF…';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        _toast('Aucun PDF sélectionné.');
        return;
      }
      final file = result.files.single;
      final declaredSize = file.size;
      if (declaredSize > 0 &&
          _exceedsLimit(declaredSize, label: 'Ce PDF')) {
        return;
      }

      setState(() {
        _mediaProgress = 0.3;
        _mediaBusyLabel = 'Lecture du fichier…';
      });

      Uint8List? bytes = file.bytes;
      // Sur le web, `path` lance une exception si on y touche.
      final path = kIsWeb ? null : file.path;
      final hasPath = path != null && path.isNotEmpty;

      if ((bytes == null || bytes.isEmpty) && hasPath && !kIsWeb) {
        bytes = await File(path).readAsBytes();
      }

      final hasBytes = bytes != null && bytes.isNotEmpty;
      if (!hasBytes) {
        _toast(
          kIsWeb
              ? 'Impossible de lire ce PDF dans le navigateur. '
                  'Choisis un fichier ≤ 3 Mo, ou utilise l’app Android.'
              : 'Impossible de lire ce PDF. Réessaie avec un autre fichier.',
        );
        return;
      }
      final pdfBytes = bytes;
      if (_exceedsLimit(pdfBytes.length, label: 'Ce PDF')) {
        return;
      }

      // Aperçu immédiat (même cadre que l’image).
      setState(() {
        _imageBytes = null;
        _imagePath = null;
        _imageName = null;
        _clearedExistingImage = true;
        _clearedExistingPdf = false;
        _pdfPath = hasPath ? path : null;
        _pdfName = file.name.isNotEmpty ? file.name : 'document.pdf';
        _pdfBytes = Uint8List.fromList(pdfBytes);
        _pdfThumbBytes = null;
        _pdfPageCount = 0;
        _bgColor = null;
        _mediaProgress = 0.55;
        _mediaBusyLabel = 'Génération de la miniature…';
        if (_kind == 'discussion' || _kind == 'question') {
          _kind = 'support';
        }
      });
      await _scrollToMedia();

      final rendered = await renderPdfThumbnail(data: pdfBytes);
      if (!mounted) return;
      setState(() {
        _pdfThumbBytes = rendered.bytes;
        _pdfPageCount = rendered.pageCount;
        _mediaProgress = 1;
        _mediaBusyLabel = rendered.hasImage ? 'Aperçu prêt' : 'PDF joint';
      });
      if (!rendered.hasImage) {
        _toast(
          rendered.error ??
              'PDF joint — aperçu indisponible, tu peux quand même publier.',
        );
      }
    } catch (e) {
      _toast('Erreur PDF : ${apiErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _mediaBusy = false;
          _mediaBusyLabel = '';
          _mediaProgress = 0;
        });
      }
    }
  }

  Future<void> _scrollToMedia() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final ctx = _mediaSectionKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  void _clearPdf() {
    if (_mediaBusy || _loading) return;
    setState(() {
      _pdfBytes = null;
      _pdfThumbBytes = null;
      _pdfPath = null;
      _pdfName = null;
      _pdfPageCount = 0;
      _clearedExistingPdf = true;
      if (StatusBackgrounds.isShortEnough(_content.text)) {
        _bgColor ??= StatusBackgrounds.defaultHex;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_loading || _mediaBusy) return;
    setState(() {
      _mediaBusy = true;
      _mediaProgress = 0.12;
      _mediaBusyLabel = source == ImageSource.camera
          ? 'Ouverture de la caméra…'
          : 'Chargement de l’image…';
    });
    try {
      Uint8List? bytes;
      String? path;
      String? name;

      // Sur le web, FilePicker est plus fiable que image_picker pour la galerie.
      if (kIsWeb && source == ImageSource.gallery) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
          allowMultiple: false,
        );
        if (result == null || result.files.isEmpty) {
          _toast('Aucune image sélectionnée.');
          return;
        }
        final file = result.files.single;
        bytes = file.bytes;
        path = kIsWeb ? null : file.path;
        name = file.name;
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (file == null) {
          _toast('Aucune image sélectionnée.');
          return;
        }
        setState(() {
          _mediaProgress = 0.5;
          _mediaBusyLabel = 'Optimisation de l’image…';
        });
        bytes = await file.readAsBytes();
        path = file.path;
        name = file.name;
      }

      if (bytes == null || bytes.isEmpty) {
        _toast('Impossible de lire cette image.');
        return;
      }
      if (_exceedsLimit(bytes.length, label: 'Cette image')) {
        return;
      }

      final switchedFromAcademic = _needsPdf;
      setState(() {
        _pdfBytes = null;
        _pdfThumbBytes = null;
        _pdfPath = null;
        _pdfName = null;
        _pdfPageCount = 0;
        _clearedExistingPdf = true;
        _clearedExistingImage = false;
        _imagePath = path;
        _imageName = name;
        _imageBytes = bytes;
        _bgColor = null;
        _mediaProgress = 1;
        // Une image seule ne valide pas TFC/mémoire (PDF requis).
        if (switchedFromAcademic) {
          _kind = 'discussion';
        }
      });
      await _scrollToMedia();
      if (switchedFromAcademic) {
        _toast(
          'Image ajoutée. Type repassé en « Publication » '
          '(TFC / mémoire exigent un PDF).',
        );
      }
    } catch (e) {
      _toast('Erreur image : ${apiErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _mediaBusy = false;
          _mediaBusyLabel = '';
          _mediaProgress = 0;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      _universityId = user.universityId.isEmpty ? null : user.universityId;
      _universityName = user.university.isEmpty ? null : user.university;
      _facultyId = user.facultyId.isEmpty ? null : user.facultyId;
      _facultyName = user.faculty.isEmpty ? null : user.faculty;
      _promotionId = user.promotionId.isEmpty ? null : user.promotionId;
      _promotionName = user.promotion.isEmpty
          ? (user.level.isEmpty ? null : user.level)
          : user.promotion;
    }

    final editing = widget.editingPost;
    if (editing != null) {
      _content.text = editing.content;
      _kind = editing.kind;
      _pdfPageCount = editing.pageCount;
      _bgColor = editing.backgroundColor.trim().isEmpty
          ? null
          : editing.backgroundColor;
      final uni = PostAcademicTags.universityOf(editing);
      final fac = PostAcademicTags.facultyOf(editing);
      final promo = PostAcademicTags.promotionOf(editing);
      if (uni != null && uni.isNotEmpty) _universityName = uni;
      if (fac != null && fac.isNotEmpty) _facultyName = fac;
      if (promo != null && promo.isNotEmpty) _promotionName = promo;
    }

    _content.addListener(() {
      if (!StatusBackgrounds.isShortEnough(_content.text) || _hasMedia) {
        _bgColor = null;
      } else {
        _bgColor ??= StatusBackgrounds.defaultHex;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _content.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final blocked = _publishBlockedReason;
    if (blocked != null) {
      _toast(blocked);
      return;
    }
    final content = _content.text.trim();
    final title = content.isEmpty
        ? switch (_kind) {
            'tp' => 'Nouveau TP',
            'exam' => 'Examen partagé',
            'rapport' => 'Rapport de stage',
            'projet_tutore' => 'Projet tuteuré',
            'tfc' => 'TFC partagé',
            'memoire' => 'Mémoire partagée',
            'summary' => 'Résumé partagé',
            'notes' => 'Notes partagées',
            'support' => 'Support partagé',
            _ => 'Publication',
          }
        : (content.length > 80 ? '${content.substring(0, 77)}…' : content);

    final bg = (_canUseBg && _bgColor != null)
        ? _bgColor!
        : (_canUseBg ? StatusBackgrounds.defaultHex : '');

    setState(() {
      _loading = true;
      _mediaProgress = 0.2;
      _mediaBusyLabel = 'Envoi en cours…';
    });
    try {
      final tags = <String>[_kind];
      if (bg.isNotEmpty) tags.add(StatusBackgrounds.tagFor(bg));
      tags.add(PostAcademicTags.encodeUniversity(_universityName!));
      tags.add(PostAcademicTags.encodeFaculty(_facultyName!));
      tags.add(PostAcademicTags.encodePromotion(_promotionName!));

      final deptId = int.tryParse(
        (ref.read(authStateProvider).valueOrNull?.departmentId ?? ''),
      );

      setState(() => _mediaProgress = 0.55);

      final repo = ref.read(communityRepositoryProvider);
      final saved = _isEditing
          ? await repo.updatePost(
              id: widget.editingPost!.id,
              title: title,
              content: content.isEmpty ? title : content,
              kind: _kind,
              departmentId: deptId,
              filePath: _pdfPath,
              fileBytes: _pdfBytes,
              fileName: _pdfName,
              imagePath: _imagePath,
              imageBytes: _imageBytes,
              imageName: _imageName,
              backgroundColor: bg,
              pageCount: _pdfPageCount,
              tags: tags,
            )
          : await repo.createPost(
              title: title,
              content: content.isEmpty ? title : content,
              kind: _kind,
              departmentId: deptId,
              filePath: _pdfPath,
              fileBytes: _pdfBytes,
              fileName: _pdfName,
              imagePath: _imagePath,
              imageBytes: _imageBytes,
              imageName: _imageName,
              backgroundColor: bg,
              pageCount: _pdfPageCount,
              tags: tags,
            );
      if ((_pdfBytes != null && _pdfBytes!.isNotEmpty) && !saved.hasPdf) {
        throw Exception(
          'Le PDF n’a pas été enregistré par le serveur. Réessaie avec un fichier plus petit.',
        );
      }
      setState(() => _mediaProgress = 1);
      ref.invalidate(postsProvider('community'));
      ref.invalidate(timelinePostsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Publication mise à jour.'
                : (saved.hasPdf
                    ? 'Publication envoyée avec le PDF.'
                    : 'Publication envoyée.'),
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _mediaBusyLabel = '';
          _mediaProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: (_loading || _mediaBusy) ? null : () => context.pop(),
          icon: Icon(Icons.close, color: AkadexColors.primary, size: 26),
        ),
        title: Text(
          _isEditing ? 'Modifier la publication' : 'Nouvelle publication',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF050505),
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.more_horiz, color: AkadexColors.primary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: (_mediaBusy || _loading)
              ? LinearProgressIndicator(
                  value: _mediaProgress > 0 && _mediaProgress < 1
                      ? _mediaProgress
                      : null,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE7F3FF),
                  color: TimelineTokens.of(context).likeActive,
                )
              : Container(height: 0.5, color: const Color(0xFFCED0D4)),
        ),
      ),
      body: Stack(
        children: [
          Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _UserRow(user: user),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final k in _kinds) ...[
                        _KindChip(
                          icon: k.$3,
                          label: k.$2,
                          selected: _kind == k.$1,
                          onTap: () => setState(() => _kind = k.$1),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_canUseBg && _bgColor != null)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 220),
                    color: StatusBackgrounds.parse(_bgColor!),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: TextField(
                      controller: _content,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: 'Quoi de neuf ?',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0x99FFFFFF),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: _content,
                    maxLines: null,
                    minLines: 5,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.35,
                      color: Color(0xFF050505),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Quoi de neuf ?',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        color: Color(0xFF65676B),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (!_hasMedia) ...[
                  const SizedBox(height: 16),
                  Text(
                    _canUseBg
                        ? 'Fond coloré'
                        : 'Fond coloré (texte court ≤ ${StatusBackgrounds.maxChars} car.)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _canUseBg
                          ? const Color(0xFF050505)
                          : const Color(0xFF65676B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: StatusBackgrounds.hexColors.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          final selected = _bgColor == null;
                          return GestureDetector(
                            onTap: () => setState(() => _bgColor = null),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? TimelineTokens.of(context).likeActive
                                      : const Color(0xFFCED0D4),
                                  width: selected ? 3 : 1,
                                ),
                              ),
                              child: const Icon(Icons.format_color_reset,
                                  size: 18),
                            ),
                          );
                        }
                        final hex = StatusBackgrounds.hexColors[i - 1];
                        final color = StatusBackgrounds.parse(hex)!;
                        final selected = _bgColor == hex;
                        final enabled = _canUseBg;
                        return GestureDetector(
                          onTap: enabled
                              ? () => setState(() => _bgColor = hex)
                              : null,
                          child: Opacity(
                            opacity: enabled ? 1 : 0.35,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _mediaSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_mediaBusy || _loading) ...[
                        Text(
                          _mediaBusyLabel.isEmpty
                              ? (_loading
                                  ? 'Publication en cours…'
                                  : 'Chargement…')
                              : _mediaBusyLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF050505),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _MediaCard(
                              icon: Icons.photo_library_outlined,
                              label: 'Galerie',
                              enabled: !_loading && !_mediaBusy,
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MediaCard(
                              icon: Icons.picture_as_pdf_outlined,
                              label: 'PDF',
                              enabled: !_loading && !_mediaBusy,
                              selected: _hasPdf,
                              onTap: _pickPdf,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MediaCard(
                              icon: Icons.photo_camera_outlined,
                              label: 'Caméra',
                              enabled: !_loading && !_mediaBusy,
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _needsPdf && !_hasPdf
                            ? 'Type « ${_kinds.firstWhere((k) => k.$1 == _kind).$2} » : PDF obligatoire (max 3 Mo)'
                            : 'PDF et images : 3 Mo maximum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _needsPdf && !_hasPdf
                              ? const Color(0xFFB54708)
                              : const Color(0xFF65676B),
                        ),
                      ),
                      if (_publishBlockedReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _publishBlockedReason!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB54708),
                          ),
                        ),
                      ],
                      if (_hasImage) ...[
                        const SizedBox(height: 14),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageBytes != null &&
                                      _imageBytes!.isNotEmpty
                                  ? Image.memory(
                                      _imageBytes!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl:
                                          widget.editingPost?.imageUrl ?? '',
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => Container(
                                        height: 180,
                                        color: const Color(0xFFF0F2F5),
                                        alignment: Alignment.center,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => Container(
                                        height: 180,
                                        color: const Color(0xFFF0F2F5),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => setState(() {
                                    _imageBytes = null;
                                    _imagePath = null;
                                    _imageName = null;
                                    _clearedExistingImage = true;
                                    if (StatusBackgrounds.isShortEnough(
                                      _content.text,
                                    )) {
                                      _bgColor ??=
                                          StatusBackgrounds.defaultHex;
                                    }
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_hasPdf) ...[
                        const SizedBox(height: 14),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: PdfPreviewCard(
                                thumbnailBytes: _pdfThumbBytes,
                                fileName: _pdfName ?? 'Document PDF',
                                pageCount: _pdfPageCount,
                                height: 180,
                                busy: _mediaBusy &&
                                    (_pdfThumbBytes == null ||
                                        _pdfThumbBytes!.isEmpty),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: _clearPdf,
                                ),
                              ),
                            ),
                            if (_pdfPageCount > 0)
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 14,
                                        color: Colors.red.shade200,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _pdfPageCount > 0
                                            ? 'PDF · $_pdfPageCount p.'
                                            : 'PDF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contexte académique *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Université, faculté et promotion sont obligatoires.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final unis =
                        ref.watch(universitiesProvider).valueOrNull ?? const [];
                    return AcademicAutocomplete(
                      key: ValueKey('pub-uni-$_universityId'),
                      label: 'Université *',
                      icon: Icons.account_balance_outlined,
                      softStyle: true,
                      selectedId: _universityId,
                      selectedName: _universityName,
                      options: [
                        for (final u in unis)
                          AcademicOption(id: u.id, name: u.name),
                      ],
                      onSelected: (id, name) => setState(() {
                        _universityId = id.isEmpty ? null : id;
                        _universityName = name.trim().isEmpty ? null : name;
                        _facultyId = null;
                        _facultyName = null;
                        _promotionId = null;
                        _promotionName = null;
                      }),
                      onCreateCustom: (name) async {
                        final id = await ref
                            .read(academicRepositoryProvider)
                            .suggestUniversity(name);
                        ref.invalidate(universitiesProvider);
                        return id;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final facs = ref
                            .watch(facultiesProvider(_universityId))
                            .valueOrNull ??
                        const [];
                    return AcademicAutocomplete(
                      key: ValueKey('pub-fac-$_universityId-$_facultyId'),
                      label: 'Faculté *',
                      softStyle: true,
                      enabled: _universityId != null ||
                          (_universityName?.isNotEmpty ?? false),
                      selectedId: _facultyId,
                      selectedName: _facultyName,
                      options: [
                        for (final f in facs)
                          AcademicOption(id: f.id, name: f.name),
                      ],
                      onSelected: (id, name) => setState(() {
                        _facultyId = id.isEmpty ? null : id;
                        _facultyName = name.trim().isEmpty ? null : name;
                        _promotionId = null;
                        _promotionName = null;
                      }),
                      onCreateCustom: _universityId == null
                          ? null
                          : (name) async {
                              final id = await ref
                                  .read(academicRepositoryProvider)
                                  .suggestFaculty(
                                    name: name,
                                    universityId: _universityId!,
                                  );
                              ref.invalidate(
                                facultiesProvider(_universityId),
                              );
                              return id;
                            },
                    );
                  },
                ),
                const SizedBox(height: 10),
                AcademicAutocomplete(
                  key: ValueKey('pub-promo-$_promotionId-$_promotionName'),
                  label: 'Promotion *',
                  softStyle: true,
                  selectedId: _promotionId,
                  selectedName: _promotionName,
                  options: const [
                    AcademicOption(id: 'L1', name: 'L1'),
                    AcademicOption(id: 'L2', name: 'L2'),
                    AcademicOption(id: 'L3', name: 'L3'),
                    AcademicOption(id: 'M1', name: 'M1'),
                    AcademicOption(id: 'M2', name: 'M2'),
                    AcademicOption(id: 'Doctorat', name: 'Doctorat'),
                  ],
                  onSelected: (id, name) => setState(() {
                    _promotionId = id.isEmpty ? null : id;
                    _promotionName = name.trim().isEmpty ? null : name;
                  }),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomInset),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFCED0D4), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E6EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Public',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Important: le thème global utilise Size.fromHeight(52)
                  // (= largeur infinie) qui casse un Row → écran blanc.
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _canPublish ? _submit : () => _toast(
                            _publishBlockedReason ??
                                'Complète le formulaire pour publier.',
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canPublish
                            ? TimelineTokens.of(context).likeActive
                            : const Color(0xFFE4E6EB),
                        disabledBackgroundColor: const Color(0xFFE4E6EB),
                        foregroundColor:
                            _canPublish ? Colors.white : const Color(0xFF65676B),
                        disabledForegroundColor: const Color(0xFFBCC0C4),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        minimumSize: const Size(96, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Enregistrer' : 'Publier',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE7F3FF) : const Color(0xFFE4E6EB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? TimelineTokens.of(context).likeActive
                    : const Color(0xFF050505),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? TimelineTokens.of(context).likeActive
                      : const Color(0xFF050505),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : 'Étudiant';
    final avatar = user?.avatarUrl;
    final initial = name[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AkadexColors.primarySoft,
          backgroundImage: avatar != null && avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar)
              : null,
          child: avatar != null && avatar.isNotEmpty
              ? null
              : Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AkadexColors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF050505),
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? const Color(0xFFE7F3FF) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(color: TimelineTokens.of(context).likeActive, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected
                      ? TimelineTokens.of(context).likeActive
                      : const Color(0xFF050505),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected
                        ? TimelineTokens.of(context).likeActive
                        : const Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

