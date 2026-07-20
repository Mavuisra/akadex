#!/usr/bin/env bash
# Build script pour Render
set -o errexit

pip install -r requirements.txt

if [ -n "${RENDER:-}" ] || [ -n "${RENDER_EXTERNAL_HOSTNAME:-}" ]; then
  if [ -z "${DATABASE_URL:-}" ]; then
    echo "ERROR: DATABASE_URL n'est pas défini sur Render."
    echo "Lie une base Postgres au service (Internal Database URL) puis redéploie."
    exit 1
  fi
fi

python manage.py collectstatic --no-input
python manage.py migrate --no-input
python manage.py showmigrations

# Seed démo (ignore si déjà présent)
python manage.py seed_demo || true
