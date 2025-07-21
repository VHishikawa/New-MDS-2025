FROM apache/hive:4.0.0

# Mantenha como root para todas as operações de setup
USER root

# Instala as dependências necessárias (wget e cliente postgresql) em uma única camada
RUN apt-get update && apt-get install -y wget postgresql-client --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Argumentos para as versões dos drivers
ARG POSTGRES_DRIVER_VERSION=42.7.3
ARG AWS_SDK_VERSION=1.12.367
ARG HADOOP_AWS_VERSION=3.3.6

# Baixa os JARs com permissão de root
RUN wget -P /opt/hive/lib/ https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar && \
    wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar && \
    wget -P /opt/hive/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar

# Agora que a configuração está completa, mude para o usuário não-privilegiado
USER hive
