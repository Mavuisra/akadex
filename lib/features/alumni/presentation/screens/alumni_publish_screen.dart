import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/utils/video_link.dart';
import '../../../../core/widgets/alumni_video_card.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';

class AlumniPublishScreen extends ConsumerStatefulWidget {
  const AlumniPublishScreen({super.key});

  @override
  ConsumerState<AlumniPublishScreen> createState() =>
      _AlumniPublishScreenState();
}

class _AlumniPublishScreenState extends ConsumerState<AlumniPublishScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _video = TextEditingController();
  String _kind = 'alumni_advice';
  VideoPlatform? _preferredPlatform;
  bool _loading = false;

  static const _kindsAlumni = [
    ('alumni_advice', 'Conseil', Icons.lightbulb_outline_rounded),
    ('alumni_path', 'Parcours', Icons.school_outlined),
    ('alumni_career', 'Carrière', Icons.work_outline_rounded),
    ('alumni_tfc', 'TFC / stage', Icons.assignment_outlined),
    ('alumni_video', 'Vidéo', Icons.videocam_outlined),
  ];

  static const _platforms = [
    (VideoPlatform.youtube, 'YouTube', Icons.play_circle_filled_rounded, Color(0xFFFF0000)),
    (VideoPlatform.tiktok, 'TikTok', Icons.music_note_rounded, Color(0xFF121212)),
    (VideoPlatform.facebook, 'Facebook', Icons.facebook_rounded, Color(0xFF1877F2)),
    (VideoPlatform.direct, 'Direct', Icons.link_rounded, AkadexColors.primary),
  ];

  VideoLinkInfo get _link => parseVideoLink(_video.text);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _video.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final isAlumni = user?.isAlumni == true;
    var kind = isAlumni ? _kind : 'question';
    final videoUrl = _video.text.trim();

    if (isAlumni && (kind == 'alumni_video' || videoUrl.isNotEmpty)) {
      final info = parseVideoLink(videoUrl);
      if (!info.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ajoute un lien YouTube, TikTok, Facebook ou une URL .mp4 valide.',
            ),
          ),
        );
        return;
      }
      kind = 'alumni_video';
    }

    setState(() => _loading = true);
    try {
      await ref.read(communityRepositoryProvider).createPost(
            title: _title.text.trim(),
            content: _content.text.trim(),
            kind: kind,
            videoUrl: videoUrl,
          );
      ref.invalidate(postsProvider('alumni'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAlumni
                  ? 'Publication envoyée — en cours d’examen par la modération.'
                  : 'Question envoyée',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isAlumni = user?.isAlumni == true;
    final showVideo = isAlumni &&
        (_kind == 'alumni_video' || _video.text.trim().isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isAlumni ? 'Publier' : 'Poser une question'),
        backgroundColor: Colors.transparent,
      ),
      body: PageAtmosphere(
        intensity: 0.7,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            FadeSlideIn(
              child: LivingHeroBanner(
                title: isAlumni
                    ? 'Partage ton expérience'
                    : 'Une question aux alumni',
                subtitle: isAlumni
                    ? 'Conseils, parcours ou vidéo YouTube / TikTok / Facebook.'
                    : 'Les diplômés de ta filière pourront te répondre.',
              ),
            ),
            if (isAlumni) ...[
              const SizedBox(height: 20),
              const FadeSlideIn(
                delay: Duration(milliseconds: 60),
                child: Text(
                  'Type de contenu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kindsAlumni.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final k = _kindsAlumni[i];
                      final selected = _kind == k.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _kind = k.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 108,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: selected ? AkadexColors.brandGradient : null,
                            color: selected ? null : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : AkadexColors.border,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AkadexColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                k.$3,
                                color: selected
                                    ? Colors.white
                                    : AkadexColors.primary,
                              ),
                              const Spacer(),
                              Text(
                                k.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.white
                                      : AkadexColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex. Ma routine de révision L3',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: TextField(
                controller: _content,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                  alignLabelWithHint: true,
                  hintText: 'Raconte ton expérience…',
                ),
              ),
            ),
            if (isAlumni) ...[
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Row(
                  children: [
                    const Text(
                      'Vidéo',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AkadexColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'YouTube · TikTok · Facebook · MP4',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AkadexColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _platforms)
                      FilterChip(
                        selected: _preferredPlatform == p.$1 ||
                            (_preferredPlatform == null &&
                                _link.platform == p.$1),
                        avatar: Icon(p.$3, size: 18, color: p.$4),
                        label: Text(p.$2),
                        onSelected: (_) {
                          setState(() {
                            _preferredPlatform = p.$1;
                            if (_kind != 'alumni_video') {
                              _kind = 'alumni_video';
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: TextField(
                  controller: _video,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Lien vidéo',
                    hintText: _preferredPlatform != null
                        ? parseVideoLink('').hint.replaceFirst(
                              'Colle un lien YouTube, TikTok, Facebook ou MP4',
                              switch (_preferredPlatform!) {
                                VideoPlatform.youtube =>
                                  'https://youtube.com/watch?v=…',
                                VideoPlatform.tiktok =>
                                  'https://www.tiktok.com/@…/video/…',
                                VideoPlatform.facebook =>
                                  'https://www.facebook.com/watch/?v=…',
                                VideoPlatform.direct =>
                                  'https://…/video.mp4',
                                VideoPlatform.unknown => 'Colle ton lien…',
                              },
                            )
                        : 'Colle un lien YouTube, TikTok, Facebook ou .mp4',
                    prefixIcon: Icon(
                      _link.isValid
                          ? Icons.check_circle_rounded
                          : Icons.link_rounded,
                      color: _link.isValid
                          ? AkadexColors.success
                          : AkadexColors.inkMuted,
                    ),
                    suffixIcon: _video.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _video.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                  ),
                ),
              ),
              if (_link.isValid) ...[
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu · ${_link.label}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AkadexColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AlumniVideoCard(url: _link.url, title: _title.text),
                    ],
                  ),
                ),
              ] else if (showVideo && _video.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Lien non reconnu — utilise YouTube, TikTok, Facebook ou un .mp4',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isAlumni ? 'Publier maintenant' : 'Envoyer la question',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
