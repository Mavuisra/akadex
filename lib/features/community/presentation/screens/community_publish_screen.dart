import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/theme/status_backgrounds.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

/// Écran « Nouvelle publication » inspiré Facebook.
class CommunityPublishScreen extends ConsumerStatefulWidget {
  const CommunityPublishScreen({super.key});

  @override
  ConsumerState<CommunityPublishScreen> createState() =>
      _CommunityPublishScreenState();
}

class _CommunityPublishScreenState
    extends ConsumerState<CommunityPublishScreen> {
  final _content = TextEditingController();

  String _kind = 'discussion';
  bool _loading = false;
  String? _bgColor;

  String? _pdfPath;
  String? _pdfName;
  Uint8List? _pdfBytes;

  String? _imagePath;
  String? _imageName;
  Uint8List? _imageBytes;

  static const _kinds = [
    ('discussion', 'Publication', Icons.edit_outlined),
    ('exam', 'Examen', Icons.assignment_turned_in_outlined),
    ('tp', 'TP / TD', Icons.science_outlined),
    ('summary', 'Résumé', Icons.menu_book_outlined),
    ('notes', 'Notes', Icons.notes_rounded),
    ('support', 'Support', Icons.description_outlined),
    ('question', 'Question', Icons.help_outline_rounded),
  ];

  bool get _hasMedia =>
      _pdfBytes != null ||
      (_pdfPath != null && _pdfPath!.isNotEmpty) ||
      _imageBytes != null ||
      (_imagePath != null && _imagePath!.isNotEmpty);

  bool get _canUseBg =>
      !_hasMedia && StatusBackgrounds.isShortEnough(_content.text);

  bool get _canPublish =>
      _content.text.trim().isNotEmpty || _hasMedia;

  @override
  void initState() {
    super.initState();
    _content.addListener(() {
      if (!StatusBackgrounds.isShortEnough(_content.text) || _hasMedia) {
        _bgColor = null;
      } else {
        // Texte court sans média → fond coloré par défaut (style Facebook).
        _bgColor ??= StatusBackgrounds.defaultHex;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _pdfPath = file.path;
      _pdfName = file.name;
      _pdfBytes = file.bytes;
      _bgColor = null;
      if (_kind == 'discussion') _kind = 'support';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imagePath = file.path;
      _imageName = file.name;
      _imageBytes = bytes;
      _bgColor = null;
    });
  }

  Future<void> _submit() async {
    final content = _content.text.trim();
    if (!_canPublish) return;

    final title = content.isEmpty
        ? (_kind == 'tp'
            ? 'Nouveau TP'
            : _kind == 'exam'
                ? 'Examen partagé'
                : 'Publication')
        : (content.length > 80 ? '${content.substring(0, 77)}…' : content);

    final bg = (_canUseBg && _bgColor != null)
        ? _bgColor!
        : (_canUseBg ? StatusBackgrounds.defaultHex : '');

    setState(() => _loading = true);
    try {
      final tags = <String>[_kind];
      if (bg.isNotEmpty) tags.add(StatusBackgrounds.tagFor(bg));

      await ref.read(communityRepositoryProvider).createPost(
            title: title,
            content: content.isEmpty ? title : content,
            kind: _kind,
            filePath: _pdfPath,
            fileBytes: _pdfBytes,
            fileName: _pdfName,
            imagePath: _imagePath,
            imageBytes: _imageBytes,
            imageName: _imageName,
            backgroundColor: bg,
            tags: tags,
          );
      ref.invalidate(postsProvider('community'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication envoyée.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: AkadexColors.primary, size: 26),
        ),
        title: const Text(
          'Nouvelle publication',
          style: TextStyle(
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
          child: Container(height: 0.5, color: const Color(0xFFCED0D4)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
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
                                      ? TimelineTokens.likeActive
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
                if (_imageBytes != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() {
                              _imageBytes = null;
                              _imagePath = null;
                              _imageName = null;
                              if (StatusBackgrounds.isShortEnough(_content.text)) {
                                _bgColor ??= StatusBackgrounds.defaultHex;
                              }
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_pdfBytes != null ||
                    (_pdfPath != null && _pdfPath!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf,
                            color: Colors.red.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pdfName ?? 'Document PDF prêt à publier',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _pdfBytes = null;
                            _pdfPath = null;
                            _pdfName = null;
                            if (StatusBackgrounds.isShortEnough(_content.text)) {
                              _bgColor ??= StatusBackgrounds.defaultHex;
                            }
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MediaCard(
                        icon: Icons.photo_library_outlined,
                        label: 'Galerie',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MediaCard(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                        onTap: _pickPdf,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MediaCard(
                        icon: Icons.photo_camera_outlined,
                        label: 'Caméra',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomInset),
              decoration: const BoxDecoration(
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
                      onPressed: _canPublish && !_loading ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TimelineTokens.likeActive,
                        disabledBackgroundColor: const Color(0xFFE4E6EB),
                        foregroundColor: Colors.white,
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
                          : const Text(
                              'Publier',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
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
                    ? TimelineTokens.likeActive
                    : const Color(0xFF050505),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? TimelineTokens.likeActive
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF050505)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
