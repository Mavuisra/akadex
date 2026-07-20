#!/usr/bin/env bash
# Build script pour Render (dépendances + static)
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
