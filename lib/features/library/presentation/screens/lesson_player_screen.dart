import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/utils/video_link.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

/// Page de lecture complète style YouTube / Coursera (player + playlist).
class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    required this.lesson,
    required this.courseId,
    this.modules = const [],
    this.courseTitle = '',
  });

  final String lessonId;
  final CourseLessonItem lesson;
  final String courseId;
  final List<CourseModuleItem> modules;
  final String courseTitle;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  late CourseLessonItem _current;
  VideoPlayerController? _video;
  ChewieController? _chewie;
  YoutubePlayerController? _yt;
  bool _ready = false;
  String? _error;
  bool _isYoutube = false;

  String get _prefsKey => 'lesson_pos_${_current.id}';

  List<CourseLessonItem> get _playlist {
    final all = <CourseLessonItem>[];
    for (final m in widget.modules) {
      all.addAll(m.lessons);
    }
    if (all.isEmpty) all.add(_current);
    return all;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.lesson;
    _initPlayer();
  }

  Future<void> _disposePlayers() async {
    await _persistProgress();
    _video?.removeListener(_onTick);
    _chewie?.dispose();
    _video?.dispose();
    _chewie = null;
    _video = null;
    _yt?.close();
    _yt = null;
  }

  Future<void> _switchLesson(CourseLessonItem lesson) async {
    if (lesson.id == _current.id) return;
    setState(() {
      _ready = false;
      _error = null;
      _current = lesson;
    });
    await _disposePlayers();
    await _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = _current.videoUrl;
    if (url.isEmpty) {
      setState(() {
        _error = _current.contentType == 'video'
            ? 'Aucune URL vidéo.'
            : null;
        _ready = true;
      });
      return;
    }

    final info = parseVideoLink(url);
    if (info.platform == VideoPlatform.youtube &&
        info.youtubeId != null &&
        info.youtubeId!.isNotEmpty) {
      _isYoutube = true;
      final controller = YoutubePlayerController.fromVideoId(
        videoId: info.youtubeId!,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
      setState(() {
        _yt = controller;
        _ready = true;
        _error = null;
      });
      return;
    }

    _isYoutube = false;
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefsKey) ?? 0;
      int resume = saved;
      try {
        final remote = await ref
            .read(academicRepositoryProvider)
            .fetchLessonProgress(_current.id);
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
      );
      controller.addListener(_onTick);

      setState(() {
        _video = controller;
        _chewie = chewie;
        _ready = true;
        _error = null;
      });
    } catch (_) {
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
            _current.id,
            positionSeconds: pos,
            completed: completed,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _video?.removeListener(_onTick);
    _persistProgress();
    _chewie?.dispose();
    _video?.dispose();
    _yt?.close();
    super.dispose();
  }

  Widget _player() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_current.videoUrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(_current.contentType),
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _current.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (_current.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _current.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (_isYoutube && _yt != null) {
      return YoutubePlayer(controller: _yt!, aspectRatio: 16 / 9);
    }
    if (_chewie != null) return Chewie(controller: _chewie!);
    return const SizedBox.shrink();
  }

  IconData _iconFor(String type) => switch (type) {
        'quiz' => Icons.quiz_outlined,
        'exercise' || 'tp' || 'td' => Icons.fitness_center_outlined,
        'assignment' => Icons.assignment_outlined,
        'pdf' => Icons.picture_as_pdf_outlined,
        'text' => Icons.article_outlined,
        _ => Icons.play_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;
    final title = widget.courseTitle.isNotEmpty
        ? widget.courseTitle
        : _current.title;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1D1F),
        foregroundColor: Colors.white,
        title: const Text(
          'Aperçu du cours',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1.25,
              ),
            ),
          ),
          AspectRatio(aspectRatio: 16 / 9, child: _player()),
          Expanded(
            child: Container(
              color: const Color(0xFF1C1D1F),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Leçons du cours',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final lesson in playlist) ...[
                    Material(
                      color: lesson.id == _current.id
                          ? const Color(0xFF3E4143)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => _switchLesson(lesson),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _LessonThumb(lesson: lesson, active: lesson.id == _current.id),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (lesson.id == _current.id)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            lesson.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        lesson.contentType.toUpperCase(),
                                        if (lesson.durationSeconds > 0)
                                          '${lesson.durationSeconds ~/ 60} min',
                                      ].join(' · '),
                                      style: const TextStyle(
                                        color: Color(0xFFD1D7DC),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3E4143)),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _current.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (_current.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _current.description,
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                        ],
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

class _LessonThumb extends StatelessWidget {
  const _LessonThumb({required this.lesson, required this.active});

  final CourseLessonItem lesson;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final yt = parseVideoLink(lesson.videoUrl);
    final thumb = yt.thumbnailUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 96,
        height: 54,
        child: thumb != null
            ? CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: active ? AkadexColors.primary : const Color(0xFF3E4143),
      alignment: Alignment.center,
      child: Icon(
        lesson.contentType == 'video'
            ? Icons.play_arrow
            : Icons.description_outlined,
        color: Colors.white70,
      ),
    );
  }
}
