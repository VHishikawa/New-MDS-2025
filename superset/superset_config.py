# superset/superset_config.py (Versão Final Corrigida e Otimizada)

import os
from superset.utils.log import DBEventLogger
from celery.schedules import crontab

# --- CONFIGURAÇÃO BÁSICA E DE PROXY ---
SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")

# --- CORREÇÃO PARA PROXY REVERSO (A PARTE MAIS IMPORTANTE) ---
# Habilita o middleware do Flask para corrigir os cabeçalhos de proxy.
# Isso é essencial para o Superset entender que está rodando atrás de um proxy
# e em um subdiretório.
ENABLE_PROXY_FIX = True

# Configura o middleware para confiar nos cabeçalhos enviados pelo Nginx.
# O 'x_prefix: 1' é o mais importante aqui, pois ele vai ler o cabeçalho
# 'X-Forwarded-Prefix' que configuramos no Nginx.
PROXY_FIX_CONFIG = {
    'x_for': 1, 
    'x_proto': 1, 
    'x_host': 1, 
    'x_port': 1, 
    'x_prefix': 1
}


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