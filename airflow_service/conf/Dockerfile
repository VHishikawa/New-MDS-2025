# new_mds/airflow_service/conf/Dockerfile

# Usa a imagem oficial do Airflow como base, AGORA COM PYTHON 3.12
FROM apache/airflow:2.10.3-python3.12

# Define variáveis de ambiente para o Spark
ENV PATH=$PATH:/opt/spark/bin:/opt/spark/sbin

# Volta para root para instalações de sistema
USER root
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    libpq-dev \
    git \
    wget \
    tar \
    openjdk-17-jdk \
    curl procps \
    libsnappy-dev \
    liblz4-dev \
    libzstd-dev \
    libgmp-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- INÍCIO DOS AJUSTES: INSTALAÇÃO DO SPARK NO CONTAINER AIRFLOW ---
# Baixa e instala o Spark com Hadoop (versão 3.5.6 com Hadoop 3)
ARG SPARK_VERSION=3.5.6
ARG HADOOP_VERSION=3
ARG SPARK_DISTRO=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
# A variável SPARK_URL não é mais usada para download direto, mas mantida por clareza.
ARG SPARK_URL=https://dlcdn.apache.org/spark/spark-3.5.6/${SPARK_DISTRO}.tgz

# Copia o arquivo Spark que você baixou localmente e o descompacta dentro do contêiner.
# >>>>> IMPORTANTE: CERTIFIQUE-SE de que o arquivo 'spark-3.5.6-bin-hadoop3.tgz' esteja na pasta './airflow_service/conf/' do seu projeto. <<<<<
COPY airflow_service/conf/spark-3.5.6-bin-hadoop3.tgz /tmp/spark.tgz
RUN mkdir -p /opt/spark && \
    tar -xzf /tmp/spark.tgz -C /opt/spark --strip-components=1 && \
    chmod -R 755 /opt/spark && \
    rm /tmp/spark.tgz

# Configura o JAVA_HOME (necessário para o SparkSubmitOperator e JVM do Spark)
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# Define SPARK_HOME APÓS a instalação
ENV SPARK_HOME=/opt/spark

# **NOVO: Copia os JARs do Hadoop S3A para o diretório de JARs do Spark**
# >>>>> IMPORTANTE: Crie a pasta './airflow_service/conf/hadoop_jars/' no seu projeto local
# e coloque 'hadoop-aws-3.3.5.jar' e 'aws-java-sdk-bundle-1.12.316.jar' nela. <<<<<
RUN mkdir -p ${SPARK_HOME}/jars/s3a/
COPY airflow_service/conf/hadoop_jars/hadoop-aws-3.3.4.jar ${SPARK_HOME}/jars/s3a/hadoop-aws-3.3.4.jar
COPY airflow_service/conf/hadoop_jars/aws-java-sdk-bundle-1.12.316.jar ${SPARK_HOME}/jars/s3a/aws-java-sdk-bundle-1.12.316.jar

# Copia os arquivos de configuração do Spark para dentro do container do Airflow
COPY airflow_service/conf/log4j2.properties ${SPARK_HOME}/conf/log4j2.properties
COPY airflow_service/conf/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf
# --- FIM DOS AJUSTES: INSTALAÇÃO DO SPARK NO CONTAINER AIRFLOW ---

# Volta para o usuário airflow
USER airflow

# Instala as bibliotecas Python
RUN pip install --no-cache-dir \
    apache-airflow-providers-cncf-kubernetes==7.11.0 \
    apache-airflow-providers-docker==3.8.0 \
    apache-airflow-providers-amazon==8.16.0 \
    apache-airflow-providers-google==12.0.0 \
    apache-airflow-providers-microsoft-azure==8.0.0 \
    apache-airflow-providers-celery \
    apache-airflow-providers-apache-spark \
    #apache-airflow-providers-prometheus==3.1.0 \
    #apache-airflow-providers-postgres\
    #apache-airflow-providers-redis \
    #apache-airflow-providers-sqlite \
    #apache-airflow-providers-elasticsearch \
    #apache-airflow-providers-http \
    #apache-airflow-providers-ssh \
    #apache-airflow-providers-odbc \
    #apache-airflow-providers-trino \
    #apache-airflow-providers-apache-hive \
    #apache-airflow-providers-apache-druid \
    #apache-airflow-providers-apache-kafka \
    #apache-airflow-providers-apache-hadoop \
    delta-spark==3.1.0 \
    pandas==2.1.4 \
    numpy==1.26.4 \
    scikit-learn==1.5.0 \
    seaborn==0.13.2 \
    matplotlib==3.9.0 \
    google-cloud-storage==2.18.2 \
    azure-storage-blob==12.23.1 \
    boto3==1.34.120 \
    great-expectations==0.18.9 \
    fastparquet \
    openpyxl \
    pyarrow \
    jupyterlab==4.2.0 \
    notebook==7.2.1 \
    ipykernel==6.29.5 \
    psycopg2-binary==2.9.9 \
    redis==5.0.0 \
    dbt-core==1.8.2 \
    dbt-trino==1.8.1

# Expõe portas para o driver do Spark se o driver for executado no worker do Airflow
EXPOSE 7007
EXPOSE 7008