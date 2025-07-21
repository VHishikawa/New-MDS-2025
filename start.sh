#!/bin/bash
# Script Mestre para iniciar a plataforma de dados em qualquer ambiente

# Garante que o script pare se algum comando falhar
set -e

# --- Validação do Ambiente ---
ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "ERRO: Você precisa especificar um ambiente."
    echo "Uso: ./start.sh [local|dev|hmg|prod]"
    exit 1
fi
echo ">>> Iniciando ambiente: $ENVIRONMENT <<<"


# --- Preparação do Ambiente ---
echo "--> Verificando rede compartilhada mds_network..."
docker network inspect mds_network >/dev/null 2>&1 || \
    docker network create mds_network

# --- Gerenciamento do Airbyte (Standalone com abctl) ---
echo "--> Verificando e iniciando o Airbyte (via abctl)..."

# Verifica se o comando 'abctl' está disponível no PATH do sistema
if command -v abctl &> /dev/null; then
    echo "    -> Ferramenta 'abctl' do Airbyte já está instalada."
else
    echo "    -> 'abctl' não encontrado. Iniciando a instalação do Airbyte..."
    echo "       (Isso pode levar alguns minutos na primeira vez)."
    # Executa o comando de instalação oficial
    curl -LsfS https://get.airbyte.com | bash
    echo "    -> Instalação do Airbyte concluída."
    # Adiciona o diretório do abctl ao PATH da sessão atual do script
    # para que o comando 'abctl start' funcione logo em seguida.
    export PATH="$HOME/.abctl/bin:$PATH"
fi

# Garante que o Airbyte seja iniciado
echo "    -> Garantindo que os containers do Airbyte estejam em execução..."
abctl local install


# --- Construção da Stack Principal ---
echo "--> Iniciando a plataforma principal de dados..."

# Define os arquivos a serem usados. Começa com o base.
MAIN_COMPOSE_FILES="-f docker-compose.yml"

# Se o ambiente NÃO for 'local', adiciona o arquivo de override correspondente
if [ "$ENVIRONMENT" != "local" ]; then
    OVERRIDE_FILE="deploy/${ENVIRONMENT}/compose.${ENVIRONMENT}.yml"
    if [ -f "$OVERRIDE_FILE" ]; then
        MAIN_COMPOSE_FILES="$MAIN_COMPOSE_FILES -f $OVERRIDE_FILE"
        echo "    (Usando override: $OVERRIDE_FILE)"
    else
        echo "AVISO: Arquivo de override $OVERRIDE_FILE não encontrado."
    fi
fi

# Sobe a stack principal com os arquivos corretos
docker compose $MAIN_COMPOSE_FILES up -d --build --remove-orphans


# --- Exibição das Credenciais ---
# (O seu painel de boas-vindas continua aqui, sem alterações)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${GREEN}✅ Ambiente MDS - Plataforma de Dados Moderna - iniciado com sucesso!${NC}"
echo ""
echo "----------------------------------------------------------------------------------"
echo "         Links, Usuários e Senhas para os Serviços da Plataforma"
echo "----------------------------------------------------------------------------------"
echo ""

# ... (todo o seu painel de credenciais continua aqui, exatamente como estava) ...
# --- CAMADA DE ARMAZENAMENTO E CACHE ---
echo -e "${BLUE}--- 🐘 BANCOS DE DADOS E ARMAZENAMENTO 🐘 ---${NC}"
echo -e "${CYAN}🐘 PostgreSQL:${NC} jdbc:postgresql://localhost:5432/"
echo -e "  ├─ Usuário: airflow"
echo -e "  ├─ Senha: airflow"
echo -e "  └─ Bancos: airflow, superset_pg_db, airbyte_db"
echo ""
echo -e "${CYAN}💾 Redis:${NC} redis://localhost:6379"
echo ""
echo -e "${CYAN}☁️  MinIO (Data Lake):${NC}"
echo -e "  ├─ Console UI: http://localhost:9001"
echo -e "  │  ├─ Usuário: admin"
echo -e "  │  └─ Senha: minioadmin"
echo -e "  └─ S3 Endpoint (para clientes): http://localhost:9000"
echo -e "     ├─ Access Key: datalake"
echo -e "     └─ Secret Key: datalake"
echo ""
echo -e "${CYAN}🕸️  Neo4j (Grafo):${NC}"
echo -e "  ├─ Browser UI: http://localhost:7474"
echo -e "  ├─ Conexão Bolt: bolt://localhost:7687"
echo -e "  ├─ Usuário: neo4j"
echo -e "  └─ Senha: admin123"
echo ""
echo -e "${CYAN}🍃 MongoDB (NoSQL):${NC}"
echo -e "  ├─ String de Conexão: mongodb://mongoadmin:mongopassword@localhost:40017/"
echo -e "  ├─ Usuário: mongoadmin"
echo -e "  └─ Senha: mongopassword"
echo ""

# --- CAMADA DE ORQUESTRAÇÃO E PROCESSAMENTO ---
echo -e "${BLUE}--- ⚙️  ORQUESTRAÇÃO E PROCESSAMENTO ⚙️ ---${NC}"
echo -e "${CYAN}💨 Apache Airflow:${NC} http://localhost:18080"
echo -e "  ├─ Usuário: airflow"
echo -e "  └─ Senha: airflow"
echo ""
echo -e "${CYAN}✨ Apache Spark:${NC}"
echo -e "  ├─ Master UI: http://localhost:9090"
echo -e "  └─ Conexão: spark://localhost:7077"
echo ""

# --- CAMADA DE STREAMING, INGESTÃO E GOVERNANÇA ---
echo -e "${BLUE}--- 🌊 INGESTÃO, GOVERNANÇA E STREAMING 🌊 ---${NC}"
echo -e "${CYAN}🚚 Apache Kafka (Stack Confluent):${NC}"
echo -e "  ├─ Bootstrap Server (local): localhost:29092"
echo -e "  ├─ Control Center: http://localhost:9021"
echo -e "  ├─ Schema Registry: http://localhost:8081"
echo -e "  ├─ Kafka Connect: http://localhost:8083"
echo -e "  └─ ksqlDB UI: http://localhost:8088"
echo ""
echo -e "${CYAN}🌊 Apache NiFi:${NC} http://localhost:8181/nifi"
echo -e "  └─ (Primeiro acesso sem credenciais, configuração via UI)"
echo ""
echo -e "${CYAN}✈️  Airbyte:${NC} http://localhost:8000"
echo -e "  ├─ Usuário: airbyte"
echo -e "  └─ Senha: password"
echo ""
echo -e "${CYAN}🏛️  OpenMetadata:${NC} http://localhost:8585"
echo -e "  ├─ E-mail: admin@open-metadata.org"
echo -e "  └─ Senha: admin"
echo ""

# --- CAMADA DE VISUALIZAÇÃO E FERRAMENTAS ---
echo -e "${BLUE}--- 📊 VISUALIZAÇÃO E FERRAMENTAS 📊 ---${NC}"
echo -e "${CYAN}🦋 Apache Superset (BI):${NC} http://localhost:8089"
echo -e "  ├─ Usuário: admin"
echo -e "  └─ Senha: admin"
echo ""
echo -e "${CYAN}⚫ Kibana (Logs e APM):${NC} http://localhost:5601"
echo ""
echo -e "${CYAN}💠 Trino (Query Engine):${NC}"
echo -e "  ├─ Trino UI: http://localhost:8086"
echo -e "  └─ Usuário (padrão): trino (ou qualquer um)"
echo ""
echo -e "${CYAN}✒️  DBeaver (Database Client):${NC} http://localhost:8989"
echo ""
echo -e "${CYAN}📓 JupyterLab (Notebooks):${NC} http://localhost:9888"
echo -e "  └─ (Sem token de acesso configurado)"
echo ""

# --- CAMADA DE CI/CD E MONITORAMENTO ---
echo -e "${BLUE}--- 🚀 CI/CD E MONITORAMENTO 🚀 ---${NC}"
echo -e "${CYAN}👷 Jenkins (CI/CD):${NC} http://localhost:8085"
echo -e "  ├─ Usuário: admin"
echo -e "  └─ ${YELLOW}Senha Inicial:${NC} Execute o comando abaixo para obter a senha:"
echo -e "      ${YELLOW}docker-compose logs jenkins | grep -A 3 'initial admin password'${NC}"
echo ""
echo -e "${CYAN}📈 Prometheus:${NC} http://localhost:19090"
echo ""
echo -e "${CYAN}🎨 Grafana:${NC} http://localhost:3000"
echo -e "  ├─ Usuário: admin"
echo -e "  └─ Senha: admin"
echo ""

echo "----------------------------------------------------------------------------------"
echo -e "${YELLOW}IMPORTANTE: Por segurança, lembre-se de alterar as senhas padrão dos serviços"
echo -e "            (Grafana, Jenkins, Airbyte, etc.) após o primeiro login!${NC}"
echo "----------------------------------------------------------------------------------"
echo ""
