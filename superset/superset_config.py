import os
from superset.utils.log import DBEventLogger
from celery.schedules import crontab

# --- CONFIGURAÇÃO BÁSICA ---
SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")

# --- CORREÇÃO PARA PROXY E SEGURANÇA ---
ENABLE_PROXY_FIX = True
PROXY_FIX_CONFIG = {
    'x_for': 1, 'x_proto': 1, 'x_host': 1, 'x_port': 1, 'x_prefix': 1
}

WTF_CSRF_ENABLED = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = True

# --- Define a página inicial após o login ---
# Usar esta variável simples é o suficiente e mais seguro.
LANDING_PAGE_AFTER_LOGIN = "/dashboard/list/"

# --- MELHORIAS DE PERFORMANCE E FUNCIONALIDADES ---
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_cache_',
    'CACHE_REDIS_URL': 'redis://redis_cache:6379/1',
}

# ... (o resto do seu arquivo de configuração continua igual)
# (CeleryConfig, FEATURE_FLAGS, etc. estão corretos)
class CeleryConfig(object):
    broker_url = "redis://redis_cache:6379/0"
    result_backend = "redis://redis_cache:6379/0"
    worker_prefetch_multiplier = 10
    task_track_started = True
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*/1"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(hour=0, minute=0),
        },
    }

CELERY_CONFIG = CeleryConfig

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_RBAC": True,
    "ALERTS_REPORTS": True,
}

EVENT_LOGGERS = [DBEventLogger()]