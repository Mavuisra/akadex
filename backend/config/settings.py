"""
Django settings for Akadex API.
"""

from datetime import timedelta
from pathlib import Path
import os

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv(
    'SECRET_KEY',
    'django-insecure-akadex-dev-change-me-in-production-2026',
)

_ON_RENDER = bool(os.getenv('RENDER')) or bool(os.getenv('RENDER_EXTERNAL_HOSTNAME'))

DEBUG = os.getenv(
    'DEBUG',
    'False' if _ON_RENDER else 'True',
).lower() in ('1', 'true', 'yes')

ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1,10.0.2.2').split(',')
    if h.strip()
]

# Render injecte automatiquement ce hostname
render_host = os.getenv('RENDER_EXTERNAL_HOSTNAME')
if render_host and render_host not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(render_host)

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'django_filters',
    'drf_spectacular',
    # Local
    'accounts',
    'academic',
    'community',
    'messaging',
    'learning',
    'payments',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# Postgres si DATABASE_URL, sinon SQLite (ok sur Render pour démo).
# Sur Render free, le disque est éphémère : migrate+seed au démarrage (start.sh).
if os.getenv('DATABASE_URL'):
    try:
        import dj_database_url
    except ImportError as exc:
        raise ImportError(
            'dj-database-url est requis quand DATABASE_URL est défini. '
            'Installe-le avec : pip install -r requirements.txt'
        ) from exc

    DATABASES = {
        'default': dj_database_url.config(
            conn_max_age=600,
            ssl_require=True,
        )
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Kinshasa'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# --- Médias : disque local (dev) ou Supabase Storage S3 (prod) ---
USE_S3_MEDIA = os.getenv('USE_S3_MEDIA', '').lower() in ('1', 'true', 'yes') or bool(
    os.getenv('AWS_S3_ENDPOINT_URL')
)

MEDIA_ROOT = BASE_DIR / 'media'
MEDIA_URL = '/media/'

STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedStaticFilesStorage',
    },
}

if USE_S3_MEDIA:
    _supabase_project = os.getenv('SUPABASE_PROJECT_REF', 'eyjhscpbdimuqetkwway')
    _bucket = os.getenv('AWS_STORAGE_BUCKET_NAME', 'course-videos-pdfs')
    _bucket_public = os.getenv('SUPABASE_BUCKET_PUBLIC', 'False').lower() in (
        '1',
        'true',
        'yes',
    )

    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID', '')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY', '')
    AWS_STORAGE_BUCKET_NAME = _bucket
    AWS_S3_ENDPOINT_URL = os.getenv(
        'AWS_S3_ENDPOINT_URL',
        f'https://{_supabase_project}.storage.supabase.co/storage/v1/s3',
    )
    AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME', 'eu-west-1')
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_S3_ADDRESSING_STYLE = 'path'
    AWS_DEFAULT_ACL = None
    AWS_S3_FILE_OVERWRITE = False
    AWS_S3_OBJECT_PARAMETERS = {'CacheControl': 'max-age=86400'}

    # Privé (recommandé) : URLs signées ~1 h renvoyées par l’API.
    # Public : lien permanent /object/public/… (avatars visibles sans auth).
    AWS_QUERYSTRING_AUTH = not _bucket_public
    AWS_QUERYSTRING_EXPIRE = int(os.getenv('AWS_QUERYSTRING_EXPIRE', '3600'))

    if _bucket_public:
        MEDIA_URL = os.getenv(
            'MEDIA_URL',
            f'https://{_supabase_project}.supabase.co/storage/v1/object/public/{_bucket}/',
        )
    else:
        MEDIA_URL = os.getenv(
            'MEDIA_URL',
            f'https://{_supabase_project}.supabase.co/storage/v1/object/authenticated/{_bucket}/',
        )

    STORAGES['default'] = {
        'BACKEND': 'config.storage_backends.SupabaseMediaStorage',
    }

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'accounts.User'

CORS_ALLOW_ALL_ORIGINS = os.getenv(
    'CORS_ALLOW_ALL_ORIGINS',
    'True' if DEBUG else 'True',
).lower() in ('1', 'true', 'yes')

CORS_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv(
        'CORS_ALLOWED_ORIGINS',
        'http://localhost:3000,http://127.0.0.1:3000',
    ).split(',')
    if o.strip()
]

CSRF_TRUSTED_ORIGINS = [
    o.strip()
    for o in os.getenv('CSRF_TRUSTED_ORIGINS', '').split(',')
    if o.strip()
]
if render_host:
    CSRF_TRUSTED_ORIGINS.append(f'https://{render_host}')

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'True').lower() in (
        '1',
        'true',
        'yes',
    )
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
    'DEFAULT_PAGINATION_CLASS': 'config.pagination.FlexiblePagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=12),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'Akadex API',
    'DESCRIPTION': 'API REST de la plateforme académique Akadex',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

# --- PawaPay (Mobile Money) ---
# Token uniquement côté serveur (.env / Render Environment).
# Strip : évite espaces / guillemets collés depuis le dashboard.
def _env_strip(key: str, default: str = '') -> str:
    raw = os.getenv(key, default) or default
    return raw.strip().strip('"').strip("'")


PAWAPAY_API_TOKEN = _env_strip('PAWAPAY_API_TOKEN')
# Défaut sandbox : les tokens dashboard démo/sandbox refusent api.pawapay.io (401).
PAWAPAY_BASE_URL = _env_strip(
    'PAWAPAY_BASE_URL',
    'https://api.sandbox.pawapay.io',
).rstrip('/')
PAWAPAY_CURRENCY = _env_strip('PAWAPAY_CURRENCY', 'USD') or 'USD'
PAWAPAY_COUNTRY = _env_strip('PAWAPAY_COUNTRY', 'COD') or 'COD'

