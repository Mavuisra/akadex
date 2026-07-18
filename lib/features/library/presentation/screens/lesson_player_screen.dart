import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    required this.lesson,
    required this.courseId,
    this.modules = const [],
  });

  final String lessonId;
  final CourseLessonItem lesson;
  final String courseId;
  final List<CourseModuleItem> modules;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _ready = false;
  String? _error;

  String get _prefsKey => 'lesson_pos_${widget.lessonId}';

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.lesson.videoUrl;
    if (url.isEmpty) {
      setState(() => _error = 'Aucune URL vidéo.');
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefsKey) ?? 0;
      int resume = saved;
      try {
        final remote = await ref
            .read(academicRepositoryProvider)
            .fetchLessonProgress(widget.lessonId);
        if (remote != null) {
          resume = (remote['position_seconds'] as num?)?.toInt() ?? resume;
        }
      } catch (_) {}

      if (resume > 0 && resume < controller.value.duration.inSeconds) {
        await controller.seekTo(Duration(seconds: resume));
      }

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.75, 1.0, 1.25, 1.5, 2.0],
        // Sous-titres : piste prévue via subtitles_url (extensible)
        additionalOptions: (context) => [
          OptionItem(
            onTap: (ctx) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.lesson.subtitlesUrl.isEmpty
                        ? 'Sous-titres non disponibles pour cette leçon.'
                        : 'Piste : ${widget.lesson.subtitlesUrl}',
                  ),
                ),
              );
            },
            iconData: Icons.closed_caption_outlined,
            title: 'Sous-titres',
          ),
        ],
      );

      controller.addListener(_onTick);

      setState(() {
        _video = controller;
        _chewie = chewie;
        _ready = true;
      });
    } catch (e) {
      setState(() => _error = 'Impossible de charger la vidéo.');
    }
  }

  void _onTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final pos = v.value.position.inSeconds;
    if (pos > 0 && pos % 5 == 0) {
      SharedPreferences.getInstance().then((p) => p.setInt(_prefsKey, pos));
    }
  }

  Future<void> _persistProgress({bool completed = false}) async {
    final pos = _video?.value.position.inSeconds ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, pos);
    try {
      await ref.read(academicRepositoryProvider).saveLessonProgress(
            widget.lessonId,
            positionSeconds: pos,
            completed: completed,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _persistProgress();
    _video?.removeListener(_onTick);
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.lesson.title, maxLines: 1),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _error != null
                ? Center(
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  )
                : !_ready || _chewie == null
                    ? const Center(child: CircularProgressIndicator())
                    : Chewie(controller: _chewie!),
          ),
          Expanded(
            child: Container(
              color: AkadexColors.background,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.lesson.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.lesson.description,
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Chapitres'),
                  const SizedBox(height: 8),
                  for (final mod in widget.modules) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          for (final l in mod.lessons)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              selected: l.id == widget.lessonId,
                              leading: Icon(
                                l.isVideo
                                    ? Icons.play_circle_outline
                                    : Icons.description_outlined,
                                color: AkadexColors.primary,
                              ),
                              title: Text(l.title),
                              onTap: l.isVideo && l.id != widget.lessonId
                                  ? () {
                                      context.pushReplacement(
                                        '/library/lesson/${l.id}/play',
                                        extra: {
                                          'lesson': l,
                                          'courseId': widget.courseId,
                                          'modules': widget.modules,
                                        },
                                      );
                                    }
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
