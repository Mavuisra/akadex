"""
WSGI config for Akadex.

Sur Render (SQLite éphémère), les tables doivent être créées au boot du worker,
pas seulement pendant le build (disque différent).
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

application = get_wsgi_application()


def _bootstrap_database() -> None:
    """migrate + seed au démarrage si AUTO_MIGRATE n'est pas désactivé."""
    flag = os.getenv('AUTO_MIGRATE', 'true').lower()
    if flag not in ('1', 'true', 'yes'):
        return

    from django.core.management import call_command

    print('[akadex] Running migrate…', flush=True)
    call_command('migrate', interactive=False, verbosity=1)
    try:
        print('[akadex] Running seed_demo…', flush=True)
        call_command('seed_demo', verbosity=1)
    except Exception as exc:  # noqa: BLE001 — ne bloque pas le boot
        print(f'[akadex] seed_demo skipped: {exc}', flush=True)
    print('[akadex] Database ready.', flush=True)


_bootstrap_database()
