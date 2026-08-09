from django.conf import settings
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
