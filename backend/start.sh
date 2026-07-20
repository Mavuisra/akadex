#!/usr/bin/env bash
# Start script Render — migrate + seed à CHAQUE démarrage
# (nécessaire avec SQLite : le disque du build ≠ disque du runtime)
set -o errexit

python manage.py migrate --no-input
python manage.py seed_demo || true

exec gunicorn config.wsgi:application --bind "0.0.0.0:${PORT:-8000}"
