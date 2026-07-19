/// Détection et normalisation des liens vidéo (YouTube, TikTok, Facebook, direct).
library;

enum VideoPlatform { youtube, tiktok, facebook, direct, unknown }

class VideoLinkInfo {
  const VideoLinkInfo({
    required this.platform,
    required this.url,
    this.youtubeId,
  });

  final VideoPlatform platform;
  final String url;
  final String? youtubeId;

  bool get isValid =>
      platform != VideoPlatform.unknown && url.trim().isNotEmpty;

  bool get isDirectPlayable =>
      platform == VideoPlatform.direct &&
      (url.contains('.mp4') ||
          url.contains('.webm') ||
          url.contains('.m3u8') ||
          url.contains('gtv-videos-bucket'));

  String get label => switch (platform) {
        VideoPlatform.youtube => 'YouTube',
        VideoPlatform.tiktok => 'TikTok',
        VideoPlatform.facebook => 'Facebook',
        VideoPlatform.direct => 'Vidéo directe',
        VideoPlatform.unknown => 'Lien',
      };

  String get hint => switch (platform) {
        VideoPlatform.youtube => 'youtube.com ou youtu.be',
        VideoPlatform.tiktok => 'tiktok.com/@…/video/…',
        VideoPlatform.facebook => 'facebook.com/watch ou fb.watch',
        VideoPlatform.direct => 'URL .mp4 / .webm',
        VideoPlatform.unknown => 'Colle un lien YouTube, TikTok, Facebook ou MP4',
      };

  String? get thumbnailUrl {
    final id = youtubeId;
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  String? get watchUrl {
    if (!isValid) return null;
    if (platform == VideoPlatform.youtube && youtubeId != null) {
      return 'https://www.youtube.com/watch?v=$youtubeId';
    }
    return url;
  }
}

VideoLinkInfo parseVideoLink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const VideoLinkInfo(platform: VideoPlatform.unknown, url: '');
  }

  final lower = trimmed.toLowerCase();
  Uri? uri;
  try {
    uri = Uri.parse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
  } catch (_) {
    return VideoLinkInfo(platform: VideoPlatform.unknown, url: trimmed);
  }

  final host = uri.host.toLowerCase();

  // YouTube
  if (host.contains('youtube.com') ||
      host.contains('youtu.be') ||
      host.contains('youtube-nocookie.com')) {
    final id = _youtubeId(uri);
    return VideoLinkInfo(
      platform: VideoPlatform.youtube,
      url: trimmed.startsWith('http') ? trimmed : uri.toString(),
      youtubeId: id,
    );
  }

  // TikTok
  if (host.contains('tiktok.com') || host.contains('vm.tiktok.com')) {
    return VideoLinkInfo(
      platform: VideoPlatform.tiktok,
      url: trimmed.startsWith('http') ? trimmed : uri.toString(),
    );
  }

  // Facebook
  if (host.contains('facebook.com') ||
      host.contains('fb.watch') ||
      host.contains('fb.com')) {
    return VideoLinkInfo(
      platform: VideoPlatform.facebook,
      url: trimmed.startsWith('http') ? trimmed : uri.toString(),
    );
  }

  // Direct media
  if (lower.contains('.mp4') ||
      lower.contains('.webm') ||
      lower.contains('.m3u8') ||
      lower.contains('gtv-videos-bucket') ||
      lower.contains('/video/') && lower.endsWith('.mp4')) {
    return VideoLinkInfo(
      platform: VideoPlatform.direct,
      url: trimmed.startsWith('http') ? trimmed : uri.toString(),
    );
  }

  return VideoLinkInfo(platform: VideoPlatform.unknown, url: trimmed);
}

String? _youtubeId(Uri uri) {
  if (uri.host.contains('youtu.be')) {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return (id != null && id.isNotEmpty) ? id : null;
  }
  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) return v;
  final parts = uri.pathSegments;
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i] == 'embed' || parts[i] == 'shorts' || parts[i] == 'live') {
      return parts[i + 1];
    }
  }
  return null;
}
