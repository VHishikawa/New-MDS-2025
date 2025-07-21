#!/bin/bash
set -e

# A LINHA MAIS IMPORTANTE: Força o shell a exportar a variável de ambiente
# para que todos os comandos 'superset' subsequentes 'enxerguem' nosso arquivo de config.
export SUPERSET_CONFIG_PATH="/app/pythonpath/superset_config.py"

echo "Running DB upgrade..."
superset db upgrade

echo "Creating admin user..."
superset fab create-admin \
  --username admin \
  --firstname Superset \
  --lastname Admin \
  --email admin@superset.com \
  --password admin || echo "Admin user already exists."

echo "Initializing Superset..."
superset init

echo "Initialization complete."