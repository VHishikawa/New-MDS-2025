#!/bin/bash
set -e

# --- Variáveis de Configuração ---
# Lista de bancos de dados que a plataforma necessita.
DATABASES_TO_CREATE=(
    "superset_pg_db"
    "metastore_db"
    "n8n_db"
    "openmetadata_ingestion_db"
)

# Lista de extensões úteis a serem instaladas.
EXTENSIONS_TO_INSTALL=(
    "uuid-ossp"
    "pg_stat_statements"
)

# Credenciais para um novo usuário dedicado de leitura.
READONLY_USER="readonly_viewer"
READONLY_PASSWORD="viewerpassword123"

# =======================================================================================
#  FUNÇÕES DE APOIO
# =======================================================================================

# Função para criar um banco de dados de forma idempotente.
create_database() {
    local db_name=$1
    if psql -lqt --username "$POSTGRES_USER" | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "Banco de dados '$db_name' já existe. Pulando."
    else
        echo "Criando banco de dados: '$db_name'..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
            CREATE DATABASE "$db_name";
EOSQL
    fi
}

# Função para instalar extensões em um banco de dados.
install_extensions() {
    local db_name=$1
    for ext in "${EXTENSIONS_TO_INSTALL[@]}"; do
        echo "Habilitando extensão '$ext' no banco de dados '$db_name'..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
            CREATE EXTENSION IF NOT EXISTS "$ext";
EOSQL
    done
}

# Função para aplicar as permissões de role para um banco de dados.
grant_permissions() {
    local db_name=$1
    echo "Aplicando permissões para os roles no banco de dados: '$db_name'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
        GRANT ALL ON SCHEMA public TO developer_role;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO developer_role;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO developer_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO developer_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO developer_role;

        GRANT USAGE ON SCHEMA public TO readonly_role;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_role;
EOSQL
}

# =======================================================================================
#  EXECUÇÃO PRINCIPAL DO SCRIPT
# =======================================================================================

echo "🚀 Iniciando script de inicialização customizado do PostgreSQL..."

# --- 1. CRIAR ROLES (GRUPOS) ---
echo "--- Criando roles 'developer_role' e 'readonly_role' (se não existirem)..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'developer_role') THEN CREATE ROLE developer_role; END IF;
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'readonly_role') THEN CREATE ROLE readonly_role; END IF;
    END \$\$;
EOSQL

# --- 2. CRIAR USUÁRIO DEDICADO PARA LEITURA ---
echo "--- Criando usuário dedicado de leitura '$READONLY_USER'..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$READONLY_USER') THEN
            CREATE USER $READONLY_USER WITH PASSWORD '$READONLY_PASSWORD';
        END IF;
    END \$\$;
    GRANT readonly_role TO $READONLY_USER;
EOSQL

# --- 3. PROCESSAR CADA BANCO DE DADOS ---
ALL_DATABASES=("${DATABASES_TO_CREATE[@]}" "$POSTGRES_DB")
for db in "${ALL_DATABASES[@]}"; do
    # Garante que não tentemos processar um nome de banco de dados vazio.
    if [ -n "$db" ]; then
        echo "-----------------------------------------------------"
        echo "Processando banco de dados: $db"
        echo "-----------------------------------------------------"
        create_database "$db"
        install_extensions "$db"
        grant_permissions "$db"
    fi
done

# --- 4. ATRIBUIR ROLE DE DESENVOLVEDOR AO USUÁRIO PRINCIPAL ---
echo "--- Atribuindo 'developer_role' ao usuário principal '$POSTGRES_USER'..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    GRANT developer_role TO "$POSTGRES_USER";
EOSQL

echo "✅ Script de inicialização do PostgreSQL foi concluído com sucesso."
