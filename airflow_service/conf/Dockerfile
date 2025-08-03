# =========================================================================================
#  ESTÁGIO 1: Builder - Usado para baixar e preparar dependências
# =========================================================================================
FROM apache/airflow:2.10.3-python3.12 AS builder

ARG SPARK_VERSION=3.5.6
ARG HADOOP_VERSION=3
ARG SPARK_TGZ=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
ARG SPARK_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TGZ}

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    tar \
    openjdk-17-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Baixa e descompacta o Spark
RUN wget --no-verbose -O /tmp/spark.tgz ${SPARK_URL} && \
    mkdir -p /opt/spark && \
    tar -xzf /tmp/spark.tgz -C /opt/spark --strip-components=1 && \
    rm /tmp/spark.tgz

# =========================================================================================
#  ESTÁGIO 2: Final - A imagem que será realmente usada
# =========================================================================================
FROM apache/airflow:2.10.3-python3.12

USER root

# Instala dependências de sistema necessárias para as bibliotecas Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    libpq-dev \
    git \
    curl \
    procps \
    libsnappy-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copia o JDK e o Spark já prontos do estágio 'builder'
COPY --from=builder /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64
COPY --from=builder /opt/spark /opt/spark

# Define as variáveis de ambiente essenciais
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin

# Copia os JARs e configurações do Spark
# Certifique-se de que os caminhos estão corretos em relação à raiz do projeto
COPY airflow_service/conf/hadoop_jars/*.jar ${SPARK_HOME}/jars/
COPY airflow_service/conf/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf
COPY airflow_service/conf/log4j2.properties ${SPARK_HOME}/conf/log4j2.properties

# --- Isola o dbt em seu próprio ambiente virtual ---
RUN python -m venv /opt/dbt_venv && \
    /opt/dbt_venv/bin/pip install --no-cache-dir dbt-core==1.8.2 dbt-trino==1.8.1

# Copia o arquivo de requisitos do Airflow
COPY airflow_service/conf/requirements.txt /tmp/requirements.txt

# Volta para o usuário airflow para instalar as dependências
USER airflow
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# --- CORREÇÃO APLICADA ---
# Troca para root para fazer a limpeza do arquivo temporário
USER root
RUN rm /tmp/requirements.txt

# Volta para o usuário airflow como padrão para a execução do container
USER airflow

# Expõe portas (opcional, mas boa prática)
EXPOSE 7007 7008
