import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../theme/akadex_theme.dart';
import '../utils/video_link.dart';

/// Carte vidéo alumni : aperçu léger ; lecture MP4 uniquement au tap (évite OOM web).
class AlumniVideoCard extends StatefulWidget {
  const AlumniVideoCard({
    super.key,
    required this.url,
    this.title = '',
  });

  final String url;
  final String title;

  @override
  State<AlumniVideoCard> createState() => _AlumniVideoCardState();
}

class _AlumniVideoCardState extends State<AlumniVideoCard> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _initFailed = false;
  bool _loading = false;
  bool _userRequestedPlay = false;

  late final VideoLinkInfo _info = parseVideoLink(widget.url);

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _chewie?.dispose();
    _chewie = null;
    _video?.dispose();
    _video = null;
  }

  Future<void> _initDirect() async {
    if (_loading || _chewie != null) return;
    setState(() {
      _loading = true;
      _initFailed = false;
    });
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(_info.url));
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _video = ctrl;
        _chewie = ChewieController(
          videoPlayerController: ctrl,
          autoPlay: true,
          looping: false,
          aspectRatio: ctrl.value.aspectRatio == 0
              ? 16 / 9
              : ctrl.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AkadexColors.primary,
            handleColor: AkadexColors.accent,
            bufferedColor: AkadexColors.primarySoft,
            backgroundColor: AkadexColors.border,
          ),
        );
        _loading = false;
      });
    } catch (_) {
      _disposePlayer();
      if (mounted) {
        setState(() {
          _initFailed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onTap() async {
    // Sur le web, ouvrir l’externe évite canvaskit / décodeurs saturés.
    if (kIsWeb || !_info.isDirectPlayable || _initFailed) {
      await _openExternal();
      return;
    }
    setState(() => _userRequestedPlay = true);
    await _initDirect();
  }

  Future<void> _openExternal() async {
    final target = _info.watchUrl ?? _info.url;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color get _platformColor => switch (_info.platform) {
        VideoPlatform.youtube => const Color(0xFFFF0000),
        VideoPlatform.tiktok => const Color(0xFF121212),
        VideoPlatform.facebook => const Color(0xFF1877F2),
        VideoPlatform.direct => AkadexColors.primary,
        VideoPlatform.unknown => AkadexColors.inkMuted,
      };

  IconData get _platformIcon => switch (_info.platform) {
        VideoPlatform.youtube => Icons.play_circle_filled_rounded,
        VideoPlatform.tiktok => Icons.music_note_rounded,
        VideoPlatform.facebook => Icons.facebook_rounded,
        VideoPlatform.direct => Icons.videocam_rounded,
        VideoPlatform.unknown => Icons.link_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (!_info.isValid) return const SizedBox.shrink();

    if (_chewie != null &&
        _video != null &&
        _video!.value.isInitialized &&
        _userRequestedPlay) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _video!.value.aspectRatio == 0
              ? 16 / 9
              : _video!.value.aspectRatio,
          child: Chewie(controller: _chewie!),
        ),
      );
    }

    final thumb = _info.thumbnailUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _onTap,
        borderRadius: BorderRadius.circular(16),
        child: _shell(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                kIsWeb
                    ? Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _gradientFallback(),
                      )
                    : CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        memCacheWidth: 640,
                        errorWidget: (_, _, _) => _gradientFallback(),
                      )
              else
                _gradientFallback(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Center(
                child: _loading
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _platformColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: _platformColor,
                        ),
                      ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _platformColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_platformIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            _info.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      kIsWeb || !_info.isDirectPlayable ? 'Ouvrir' : 'Lire',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _shell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: AkadexColors.ink, child: child),
      ),
    );
  }

  Widget _gradientFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _platformColor.withValues(alpha: 0.85),
            AkadexColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _platformIcon,
          size: 48,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
