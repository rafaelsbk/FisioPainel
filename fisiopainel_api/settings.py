import os
from pathlib import Path
from datetime import timedelta
from decouple import config, Csv

# Build paths inside the project
BASE_DIR = Path(__file__).resolve().parent

SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
# 1. Certifique-se de que o Host está listado corretamente
ALLOWED_HOSTS = ['genesis1.vps-kinghost.net', 'localhost', '127.0.0.1']

# 2. Configurações cruciais para HTTPS e Proxy
# Informa ao Django para confiar no HTTPS vindo do Nginx
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Configurações de cookies seguros para evitar 403 em operações POST/Login
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Adicione o seu domínio como origem confiável para CSRF
CSRF_TRUSTED_ORIGINS = ['https://genesis1.vps-kinghost.net']

# 3. Mantenha o CORS liberado para o seu Front-end
CORS_ALLOW_ALL_ORIGINS = True

# Redireciona trÃ¡fego HTTP para HTTPS (Ative apenas quando o SSL estiver funcional no Nginx)
SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=True, cast=bool)
# --------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'users.apps.UsersConfig',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders', # JÃ¡ presente nos seus requisitos
    'django_extensions',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware', # Deve estar sempre no topo
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# --- CONFIGURAÃ‡ÃƒO DE CORS ---
# Como vocÃª estÃ¡ tendo erro de CORS com HTTPS, verifique estas definiÃ§Ãµes:
CORS_ALLOW_ALL_ORIGINS = config('CORS_ALLOW_ALL_ORIGINS', default=True, cast=bool)

# Se preferir restringir (Recomendado para produÃ§Ã£o):
# CORS_ALLOWED_ORIGINS = [
#     "https://seu-front-end.com",
# ]
# ----------------------------

ROOT_URLCONF = 'urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'), # Deve ser 'db' no Docker
        'PORT': config('DB_PORT'),
    }
}

# ConfiguraÃ§Ãµes JWT (Baseado no seu serializers.py e settings anterior)
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'TOKEN_OBTAIN_SERIALIZER': 'users.serializers.MyTokenObtainPairSerializer',
}

AUTH_USER_MODEL = 'users.User'
STATIC_URL = 'static/'