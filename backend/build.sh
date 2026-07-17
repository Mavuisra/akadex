#!/usr/bin/env bash
# Build script pour Render
set -o errexit

pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate --no-input

# Seed optionnel (ne plante pas si déjà fait)
python manage.py seed_demo || true
