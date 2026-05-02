import os
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-pasadanow-secret-key'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.contenttypes',
    'django.contrib.auth',
    'rest_framework',
    'corsheaders',
    'pasadanow.apps.drivers.apps.DriversConfig',
    'pasadanow.apps.earnings.apps.EarningsConfig',
    'pasadanow.apps.admin_api.apps.AdminApiConfig',
    'pasadanow.apps.commuters.apps.CommutersConfig',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # ← must stay FIRST
    'django.middleware.common.CommonMiddleware',
]

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
            ],
        },
    },
]

ROOT_URLCONF = 'pasadanow.urls'

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.postgresql',
        'NAME':     os.getenv('DB_NAME', 'auth_db'),
        'USER':     os.getenv('DB_USER', 'user'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'password'),
        'HOST':     os.getenv('DB_HOST', 'db'),
        'PORT':     os.getenv('DB_PORT', '5432'),
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'pasadanow.authentication.JwtCookieAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
}

# ── CORS ────────────────────────────────────────────────────────────────────
# IMPORTANT: Never set CORS_ALLOW_ALL_ORIGINS = True together with
# CORS_ALLOW_CREDENTIALS = True — browsers reject that combination.
# Using regex patterns instead so Flutter web's random port is always covered.

CORS_ALLOW_ALL_ORIGINS = False  # must be False when using credentials
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^http://localhost(:\d+)?$',           # all localhost ports (Flutter web random port)
    r'^http://192\.168\.\d+\.\d+(:\d+)?$', # all LAN IPs (your dev machines)
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
# ────────────────────────────────────────────────────────────────────────────

JWT_SECRET   = os.getenv('JWT_SECRET', '')
APPEND_SLASH = False

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'