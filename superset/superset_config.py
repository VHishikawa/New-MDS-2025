# superset/superset_config.py

import os
from superset.utils.log import DBEventLogger

SQLALCHEMY_DATABASE_URI = os.environ.get("SUPERSET_DATABASE_URI")
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")
EVENT_LOGGERS = [DBEventLogger()]

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

UPLOAD_ENABLED = True