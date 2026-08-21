from django.conf import settings
from django.http import JsonResponse
from django.shortcuts import render


def home(request):
    """Landing marketing Akadex (racine /)."""
    return render(
        request,
        'home.html',
        {
            'play_store_url': settings.PLAY_STORE_URL,
            'app_store_url': settings.APP_STORE_URL,
        },
    )


def teacher_app(request, path=''):
    """SPA dashboard enseignant (HTML/CSS/JS) — /enseignant/."""
    return render(request, 'teacher/app.html')


def admin_app(request, path=''):
    """SPA administration Akadex — /admin/."""
    return render(request, 'platform_admin/app.html')


def storage_health(request):
    """Diagnostic stockage média (Supabase / local) — sans secrets."""
    backend = settings.STORAGES.get('default', {}).get('BACKEND', '')
    use_s3 = bool(getattr(settings, 'USE_S3_MEDIA', False))
    endpoint = (getattr(settings, 'AWS_S3_ENDPOINT_URL', '') or '')
    bucket = (getattr(settings, 'AWS_STORAGE_BUCKET_NAME', '') or '')
    host = ''
    if endpoint:
        try:
            from urllib.parse import urlparse

            host = urlparse(endpoint).netloc
        except Exception:
            host = endpoint[:80]
    return JsonResponse(
        {
            'ok': True,
            'use_s3_media': use_s3,
            'backend': backend,
            'bucket': bucket if use_s3 else '',
            'endpoint_host': host if use_s3 else '',
            'media_url_prefix': (settings.MEDIA_URL or '')[:120],
            'has_credentials': bool(
                getattr(settings, 'AWS_ACCESS_KEY_ID', '')
                and getattr(settings, 'AWS_SECRET_ACCESS_KEY', '')
            ),
            'target': 'supabase' if use_s3 else 'local_disk',
        }
    )
