#!/bin/bash
# Usar `set -e` faria o script sair em qualquer erro, o que não queremos aqui,
# pois checamos a existência dos itens manualmente.

# --- Variáveis de Configuração ---
MINIO_ALIAS="local"
MINIO_SERVER="http://minio:9000"
# Use as credenciais root definidas no seu docker-compose.yml
MINIO_ACCESS_KEY="admin"
MINIO_SECRET_KEY="minioadmin"

# --- Função para Aguardar o MinIO ---
wait_for_minio() {
    echo "Aguardando o serviço do MinIO ficar disponível..."
    # O timeout é em segundos. 120s = 2 minutos.
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

# --- Função para Criar um Bucket Idempotente ---
create_bucket() {
    local bucket_name=$1
    if ! mc ls "$MINIO_ALIAS/$bucket_name" &>/dev/null; then
        echo "Criando bucket: $bucket_name"
        mc mb "$MINIO_ALIAS/$bucket_name"
    else
        echo "Bucket '$bucket_name' já existe. Pulando."
    fi
}

# =======================================================================================
#  EXECUÇÃO PRINCIPAL DO SCRIPT
# =======================================================================================

wait_for_minio

# --- 1. CRIAR OS BUCKETS DA ARQUITETURA MEDALHÃO ---
echo "--- Iniciando criação dos buckets ---"
BUCKETS_TO_CREATE=("landing" "bronze" "silver" "gold")
for bucket in "${BUCKETS_TO_CREATE[@]}"; do
    create_bucket "$bucket"
done

# --- 2. CRIAR POLÍTICAS DE ACESSO ---
echo "--- Iniciando criação de políticas de acesso ---"
POLICY_NAME="readonly-policy"
if ! mc admin policy info $MINIO_ALIAS $POLICY_NAME &>/dev/null; then
    echo "Criando política: $POLICY_NAME"
    # Usando heredoc para criar a política diretamente no script
    cat <<EOF | mc admin policy create $MINIO_ALIAS $POLICY_NAME
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::*"]
    }
  ]
}
EOF
else
    echo "Política '$POLICY_NAME' já existe. Pulando."
fi

# --- 3. CRIAR GRUPOS DE ACESSO ---
echo "--- Iniciando criação de grupos de acesso ---"
GROUPS=("analysts-group" "developers-group")
for group in "${GROUPS[@]}"; do
    if ! mc admin group info $MINIO_ALIAS "$group" &>/dev/null; then
        echo "Criando grupo: $group"
        mc admin group add $MINIO_ALIAS "$group"
    else
        echo "Grupo '$group' já existe. Pulando."
    fi
done

# --- 4. ATRIBUIR POLÍTICAS AOS GRUPOS ---
echo "--- Atribuindo políticas aos grupos ---"
mc admin policy set $MINIO_ALIAS $POLICY_NAME group=analysts-group
mc admin policy set $MINIO_ALIAS readwrite group=developers-group
echo "Políticas atribuídas."

# --- 5. CRIAR USUÁRIO/CHAVE DE ACESSO 'datalake' ---
echo "--- Iniciando criação do usuário/chave de acesso 'datalake' ---"
ACCESS_KEY_TO_CREATE="datalake"
SECRET_KEY_TO_CREATE="datalake"

# Verifica se o usuário já existe antes de criar
if ! mc admin user info $MINIO_ALIAS $ACCESS_KEY_TO_CREATE &>/dev/null; then
    echo "Criando usuário/chave de acesso: $ACCESS_KEY_TO_CREATE"
    mc admin user add $MINIO_ALIAS $ACCESS_KEY_TO_CREATE $SECRET_KEY_TO_CREATE
else
    echo "Usuário '$ACCESS_KEY_TO_CREATE' já existe. Pulando."
fi

# Atribui a política de 'readwrite' ao novo usuário para que ele possa ler e escrever nos buckets
echo "Atribuindo política 'readwrite' ao usuário '$ACCESS_KEY_TO_CREATE'."
mc admin policy set $MINIO_ALIAS readwrite user=$ACCESS_KEY_TO_CREATE

echo "================================================="
echo "Script de inicialização do MinIO concluído com sucesso!"
echo "================================================="