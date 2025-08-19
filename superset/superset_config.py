# superset/superset_config.py (Otimizado)

import os
from superset.utils.log import DBEventLogger
from celery.schedules import crontab

# --- CONFIGURAÇÃO BÁSICA ---
# Mantém as suas configurações originais que estão corretas.
SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")
# HTTP_HEADERS = {'X-Forwarded-Prefix': '/superset'}

# --- MELHORIA 1: HABILITAR CACHE COM REDIS ---
# Para um ganho massivo de performance em dashboards.
# Usamos o serviço 'redis_cache' definido no seu docker-compose.yml.
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,  # 5 minutos
    'CACHE_KEY_PREFIX': 'superset_cache_',
    'CACHE_REDIS_URL': 'redis://redis_cache:6379/1', # DB 1 para o cache de metadados
}

# Também é possível configurar um cache separado para os dados dos gráficos
DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 3600, # 1 hora
    'CACHE_KEY_PREFIX': 'superset_data_',
    'CACHE_REDIS_URL': 'redis://redis_cache:6379/2', # DB 2 para o cache de dados
}


# --- MELHORIA 2: HABILITAR TAREFAS ASSÍNCRONAS COM CELERY ---
# Permite queries longas, alertas e relatórios em background.
# Isso exigiria um novo serviço 'superset-worker' no docker-compose.yml no futuro.
class CeleryConfig(object):
    broker_url = "redis://redis_cache:6379/0"      # DB 0 para o broker Celery
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


# --- MELHORIA 3: HABILITAR MAIS FUNCIONALIDADES (FEATURE FLAGS) ---
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_RBAC": True,  # Controle de acesso por role para dashboards
    "ALERTS_REPORTS": True,  # Habilita a criação de alertas e relatórios agendados
}


# --- OUTRAS CONFIGURAÇÕES ÚTEIS ---
# Permite o upload de arquivos CSV/Excel para criar tabelas
UPLOAD_ENABLED = True

# Para auditoria de eventos
EVENT_LOGGERS = [DBEventLogger()]
