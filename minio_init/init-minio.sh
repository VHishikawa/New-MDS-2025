#!/bin/bash
set -e # Vamos usar set -e e controlar a idempotência com 'mc ... || true'

# --- Variáveis de Configuração ---
# As credenciais ROOT são lidas do ambiente do Docker, não hardcoded.
# Isso torna o script mais seguro e acoplado à configuração do contêiner.
MINIO_ALIAS="local"
MINIO_SERVER="http://minio:9000"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD}"

# --- Nomes Configuráveis para Recursos ---
BUCKETS_TO_CREATE=("landing" "bronze" "silver" "gold")
READONLY_POLICY_NAME="readonly-policy-all-buckets"
READWRITE_POLICY_NAME="readwrite-policy-all-buckets"
DATALAKE_USER="datalake"
DATALAKE_PASSWORD="datalake"

# --- Função para Aguardar o MinIO ---
wait_for_minio() {
    echo "Aguardando o serviço do MinIO ficar disponível..."
    timeout 120s bash -c "
        until mc alias set $MINIO_ALIAS $MINIO_SERVER $MINIO_ACCESS_KEY $MINIO_SECRET_KEY &>/dev/null; do
            echo -n '.'
            sleep 2
        done
    "
    if [ $? -ne 0 ]; then
        echo "ERRO: Timeout ao aguardar o MinIO. O serviço não ficou disponível a tempo."
        exit 1
    fi
    echo "MinIO está pronto para receber comandos."
}

# =======================================================================================
#  EXECUÇÃO PRINCIPAL DO SCRIPT
# =======================================================================================

wait_for_minio

# --- 1. CRIAR OS BUCKETS DA ARQUITETURA MEDALHÃO ---
echo "--- Iniciando criação dos buckets ---"
for bucket in "${BUCKETS_TO_CREATE[@]}"; do
    if ! mc ls "$MINIO_ALIAS/$bucket" &>/dev/null; then
        echo "Criando bucket: $bucket"
        mc mb "$MINIO_ALIAS/$bucket"
    else
        echo "Bucket '$bucket' já existe. Pulando."
    fi
done

# --- 2. DEFINIR POLÍTICA DE ACESSO PÚBLICO (Exemplo) ---
echo "--- Definindo política de acesso para o bucket 'landing' ---"
# Define o bucket 'landing' como 'download', permitindo acesso público para leitura.
# Útil para alimentar dashboards ou para acesso anônimo.
# Opções: 'none', 'download', 'upload', 'public'
mc policy set download "$MINIO_ALIAS/landing"
echo "Bucket 'landing' agora tem acesso público para download."


# --- 3. CRIAR POLÍTICAS DE ACESSO CUSTOMIZADAS ---
echo "--- Iniciando criação de políticas de acesso ---"
# Política de Leitura
( mc admin policy info $MINIO_ALIAS $READONLY_POLICY_NAME &>/dev/null || \
  echo "Criando política: $READONLY_POLICY_NAME" && \
  cat <<EOF | mc admin policy create $MINIO_ALIAS $READONLY_POLICY_NAME
{
  "Version": "2012-10-17",
  "Statement": [ { "Effect": "Allow", "Action": ["s3:GetObject"], "Resource": ["arn:aws:s3:::*/*"] } ]
}
EOF
) || echo "Política '$READONLY_POLICY_NAME' já existe."

# Política de Leitura e Escrita (Explícita)
( mc admin policy info $MINIO_ALIAS $READWRITE_POLICY_NAME &>/dev/null || \
  echo "Criando política: $READWRITE_POLICY_NAME" && \
  cat <<EOF | mc admin policy create $MINIO_ALIAS $READWRITE_POLICY_NAME
{
  "Version": "2012-10-17",
  "Statement": [ { "Effect": "Allow", "Action": ["s3:*"], "Resource": ["arn:aws:s3:::*/*"] } ]
}
EOF
) || echo "Política '$READWRITE_POLICY_NAME' já existe."


# --- 4. CRIAR USUÁRIO/CHAVE DE ACESSO 'datalake' ---
echo "--- Iniciando criação do usuário/chave de acesso '$DATALAKE_USER' ---"
( mc admin user info $MINIO_ALIAS $DATALAKE_USER &>/dev/null || \
  echo "Criando usuário: $DATALAKE_USER" && \
  mc admin user add $MINIO_ALIAS $DATALAKE_USER $DATALAKE_PASSWORD
) || echo "Usuário '$DATALAKE_USER' já existe."


# --- 5. ATRIBUIR POLÍTICAS AOS USUÁRIOS ---
echo "--- Atribuindo políticas de acesso ---"
# Atribui a política de leitura e escrita ao usuário 'datalake'
mc admin policy set $MINIO_ALIAS $READWRITE_POLICY_NAME user=$DATALAKE_USER
echo "Política '$READWRITE_POLICY_NAME' atribuída ao usuário '$DATALAKE_USER'."

echo "======================================================"
echo "Script de inicialização do MinIO concluído com sucesso!"
echo "======================================================"