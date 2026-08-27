"""
Django settings for Akadex API.
"""

from datetime import timedelta
from decimal import Decimal
from pathlib import Path
import os
import warnings

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Toujours charger depuis le dossier backend/ (indépendant du CWD).
load_dotenv(BASE_DIR / '.env')
load_dotenv(BASE_DIR / 'backend' / '.env', override=False)

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
    'accounts.apps.AccountsConfig',
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
        'DIRS': [BASE_DIR / 'templates'],
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
STATICFILES_DIRS = [BASE_DIR / 'static']

# Liens boutiques (landing /). Play Store : fallback GitHub Releases tant que non publié.
PLAY_STORE_URL = os.getenv(
    'PLAY_STORE_URL',
    'https://github.com/Mavuisra/akadex/releases',
).strip()
APP_STORE_URL = os.getenv('APP_STORE_URL', '').strip()

# --- Médias : Supabase Storage (S3) — config Render dans render.yaml ---
# Tous les FileField / ImageField (lessons, documents, covers, avatars, posts, chat…)
# passent par STORAGES['default'] dès que les clés AWS_* sont présentes.
_access = os.getenv('AWS_ACCESS_KEY_ID', '').strip()
_secret = os.getenv('AWS_SECRET_ACCESS_KEY', '').strip()
_has_s3_creds = bool(_access and _secret)
_want_s3 = os.getenv('USE_S3_MEDIA', '').lower() in ('1', 'true', 'yes') or bool(
    os.getenv('AWS_S3_ENDPOINT_URL', '').strip()
)
# Activer uniquement si les secrets sont là (évite un faux S3 sans clés).
USE_S3_MEDIA = _want_s3 and _has_s3_creds

if _want_s3 and not _has_s3_creds:
    warnings.warn(
        'USE_S3_MEDIA / endpoint Supabase détecté mais AWS_ACCESS_KEY_ID / '
        'AWS_SECRET_ACCESS_KEY absents → stockage local temporaire. '
        'Sur Render, renseigne les secrets (sync: false dans render.yaml).',
        stacklevel=1,
    )

MEDIA_ROOT = BASE_DIR / 'media'
MEDIA_URL = '/media/'

# Uploads vidéo / PDF depuis le dashboard enseignant
DATA_UPLOAD_MAX_MEMORY_SIZE = int(
    os.getenv('DATA_UPLOAD_MAX_MEMORY_SIZE', str(512 * 1024 * 1024))
)  # 512 Mo
FILE_UPLOAD_MAX_MEMORY_SIZE = int(
    os.getenv('FILE_UPLOAD_MAX_MEMORY_SIZE', str(10 * 1024 * 1024))
)  # 10 Mo en RAM, puis disque

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

# --- E-mail (reset MDP, etc.) ---
# Défaut console : le code s’affiche dans les logs du serveur en local.
# Prod : EMAIL_HOST / USER / PASSWORD (+ EMAIL_BACKEND smtp).
EMAIL_BACKEND = os.getenv(
    'EMAIL_BACKEND',
    'django.core.mail.backends.console.EmailBackend',
)
EMAIL_HOST = os.getenv('EMAIL_HOST', '')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587') or '587')
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True').lower() in ('1', 'true', 'yes')
DEFAULT_FROM_EMAIL = os.getenv(
    'DEFAULT_FROM_EMAIL',
    'Akadex <noreply@akadex.app>',
)

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

# Tarifs catalogue Apprendre (USD) — source de vérité serveur.
# Le client ne doit pas imposer le montant du dépôt.
def _env_decimal(key: str, default: str) -> Decimal:
    raw = _env_strip(key, default) or default
    try:
        return Decimal(raw)
    except Exception:
        return Decimal(default)


COURSE_SALE_PRICE_USD = _env_decimal('COURSE_SALE_PRICE_USD', '15')
COURSE_LIST_PRICE_USD = _env_decimal('COURSE_LIST_PRICE_USD', '29')

# --- Firebase Cloud Messaging (push notifications) ---
# Coller le JSON du compte de service Firebase (Project settings → Service accounts).
# Sur Render : une seule ligne dans FIREBASE_CREDENTIALS_JSON (échapper les guillemets si besoin).
FIREBASE_CREDENTIALS_JSON = os.getenv('FIREBASE_CREDENTIALS_JSON', '')
FIREBASE_CREDENTIALS_PATH = os.getenv('FIREBASE_CREDENTIALS_PATH', '')

