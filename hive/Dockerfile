# Usamos a versão 4.0.0 do Hive, uma base sólida e moderna.
FROM apache/hive:4.0.0

# --- Argumentos para Versionamento ---
# Manter os argumentos no topo é uma excelente prática para facilitar atualizações.
ARG POSTGRES_DRIVER_VERSION=42.7.3
ARG AWS_SDK_VERSION=1.12.367
ARG HADOOP_AWS_VERSION=3.3.6

# Mantenha como root para todas as operações de setup
USER root

# --- OTIMIZAÇÃO: Camada Única de Setup ---
# Combinamos a instalação de pacotes e o download dos JARs em um único comando RUN.
# Isso reduz o número de camadas na imagem final, tornando-a mais eficiente.
RUN \
    # Passo 1: Instala dependências de sistema
    set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        postgresql-client && \
    \
    # Passo 2: Baixa todos os JARs necessários para o diretório de bibliotecas do Hive
    wget -P /opt/hive/lib/ "https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar" && \
    wget -P /opt/hive/lib/ "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar" && \
    wget -P /opt/hive/lib/ "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar" && \
    \
    # Passo 3: Limpa o cache do apt para manter a imagem enxuta
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- SUGESTÃO: Adicionar um Healthcheck Básico ---
# Este comando verifica se a porta do Metastore (9083) está ouvindo.
# O Docker usará isso para reportar o status de saúde do contêiner ('healthy' ou 'unhealthy').
HEALTHCHECK CMD nc -z -v localhost 9083 || exit 1

# Agora que a configuração está completa, mude para o usuário não-privilegiado
USER hive