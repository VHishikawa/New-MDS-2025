#!/bin/bash
set -e

# =======================================================================================
#  FUNÇÕES DE APOIO
# =======================================================================================

# Função para criar um banco de dados de forma idempotente (só cria se não existir)
create_database() {
    local db_name=$1
    echo "Verificando e, se necessário, criando o banco de dados: '$db_name'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        SELECT 'CREATE DATABASE $db_name'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db_name')\gexec
EOSQL
    echo "Banco de dados '$db_name' está pronto para uso."
}

# Função para aplicar as permissões de role para um banco de dados específico
grant_permissions() {
    local db_name=$1
    echo "Aplicando permissões para os roles no banco de dados: '$db_name'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
        -- Permissões para o grupo de DESENVOLVEDORES (acesso total)
        GRANT ALL ON SCHEMA public TO developer_role;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO developer_role;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO developer_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO developer_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO developer_role;

        -- Permissões para o grupo de LEITURA (acesso de apenas leitura)
        GRANT USAGE ON SCHEMA public TO readonly_role;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_role;
EOSQL
}

# =======================================================================================
#  EXECUÇÃO PRINCIPAL DO SCRIPT
# =======================================================================================

echo "Iniciando script de inicialização customizado do PostgreSQL..."

# --- 1. CRIAR BANCOS DE DADOS ADICIONAIS ---
create_database "superset_pg_db"
create_database "metastore_db"
create_database "n8n_db"
create_database "openmetadata_ingestion_db" # <-- INTEGRADO AQUI

# --- 2. CRIAR ROLES (GRUPOS) ---
echo "Criando roles 'developer_role' e 'readonly_role' (se não existirem)..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'developer_role') THEN
            CREATE ROLE developer_role;
        END IF;
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'readonly_role') THEN
            CREATE ROLE readonly_role;
        END IF;
    END
    \$\$;
EOSQL

# --- 3. ATRIBUIR ROLES AO USUÁRIO PRINCIPAL ---
# Garante que o usuário 'airflow' tenha as permissões de desenvolvedor.
# Isso é crucial para que o serviço de ingestão consiga escrever no seu banco de dados.
echo "Atribuindo 'developer_role' ao usuário '$POSTGRES_USER'..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT developer_role TO "$POSTGRES_USER";
EOSQL

# --- 4. APLICAR PERMISSÕES NOS BANCOS DE DADOS ---
# Conectamos em cada banco de dados para aplicar as permissões.
grant_permissions "airflow"
grant_permissions "superset_pg_db"
grant_permissions "metastore_db"
grant_permissions "n8n_db"
grant_permissions "openmetadata_ingestion_db" # <-- INTEGRADO AQUI

echo "Script de inicialização do PostgreSQL foi concluído com sucesso."