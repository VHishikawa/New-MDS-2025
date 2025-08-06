# DATA ENGINEERING ECOSYSTEM - MODERN DATA STACK COM DOCKER

Ambiente completo e automatizado para estudos e desenvolvimento de uma plataforma moderna de engenharia de dados, utilizando Docker e Docker Compose.

## SOFTWARES NECESSÁRIOS

#### Para a criação e uso do ambiente vamos utilizar o Git e o Docker.

  * Instalação do Docker Desktop no Windows [Docker Desktop](https://hub.docker.com/editions/community/docker-ce-desktop-windows) ou o Docker Engine no [Linux](https://docs.docker.com/engine/install/ubuntu/).
  * [Instalação do Git](https://git-scm.com/book/pt-br/v2/Come%C3%A7ando-Instalando-o-Git).

-----

## SETUP E AMBIENTES

#### Em um terminal (bash, zsh, etc.), realize o clone do projeto.

```bash
git clone https://github.com/VHishikawa/New-MDS-2025.git
cd New-MDS-2025
```

*Após o clone, entre no diretório criado.*

#### Estrutura de Ambientes

Este projeto é projetado para ser executado em quatro ambientes distintos, cada um com uma configuração de recursos progressiva. A inicialização é gerenciada pelo script `start.sh`.

  * **Local (`local`):** Ambiente base com todos os serviços em uma única instância. Ideal para testes funcionais e desenvolvimento inicial.
  * **Desenvolvimento (`dev`):** Adiciona réplicas para serviços chave como Airflow e Spark, com um leve aumento de memória. Adequado para o ciclo de desenvolvimento diário.
  * **Homologação (`hmg`):** Aumenta o número de réplicas e a alocação de memória para simular um ambiente de pré-produção, testando a resiliência e a performance.
  * **Produção (`prod`):** Configuração robusta com múltiplas réplicas e alocação de memória significativa para os serviços mais críticos (Spark, Flink, Elasticsearch). Projetado para alta disponibilidade e carga de trabalho intensa.

#### Requisitos de Hardware (Sugestões)

Cada ambiente exige mais recursos da máquina hospedeira. As sugestões abaixo são estimativas para uma execução estável:

| Recurso | `DEV` (Desenvolvimento) | `HMG` (Homologação) | `PROD` (Produção) | `Local` (Local) |
| :--- | :--- | :--- | :--- | :--- |
| **vCPUs** | 4 vCPUs | 6 vCPUs | 10 vCPUs | 4vCPUs |
| **RAM** | 16 GB | 32 GB | 72 GB | 16 GB |
| **Armazenamento** | 1 TB | 3 TB | 5 TB | 100 GB |

-----

## DOWNLOADS MANUAIS OBRIGATÓRIOS

Para permitir a comunicação do Spark e Airflow com o Data Lake (MinIO/S3), alguns arquivos precisam ser baixados manualmente e colocados nos diretórios corretos **antes** de iniciar a stack.

#### 1\. Binários do Apache Spark

Este arquivo contém a distribuição completa do Spark que será usada pelos workers.

  * **Arquivo:** `spark-3.5.6-bin-hadoop3.tgz`
  * **Destino:** `airflow_service/conf/`
  * **Link para Download:** [**spark-3.5.6-bin-hadoop3.tgz**](https://www.google.com/url?sa=E&source=gmail&q=https://archive.apache.org/dist/spark/spark-3.5.6/spark-3.5.6-bin-hadoop3.tgz)
  * **Comando Sugerido:**
    ```bash
    curl -L -o airflow_service/conf/spark-3.5.6-bin-hadoop3.tgz https://archive.apache.org/dist/spark/spark-3.5.6/spark-3.5.6-bin-hadoop3.tgz
    ```

#### 2\. JARS de Conectividade com S3 (Hadoop/AWS)

Estes arquivos são necessários para que o Spark e outros componentes do ecossistema Hadoop possam ler e escrever em sistemas de armazenamento compatíveis com S3, como o MinIO.

  * **Destino de ambos:** `airflow_service/conf/hadoop_jars/`
  * **Links para Download:**
      * [**aws-java-sdk-bundle-1.12.316.jar**](https://www.google.com/url?sa=E&source=gmail&q=https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.316/aws-java-sdk-bundle-1.12.316.jar)
      * [**hadoop-aws-3.3.4.jar**](https://www.google.com/url?sa=E&source=gmail&q=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar)
  * **Comandos Sugeridos:**
    ```bash
    # Crie o diretório se ele não existir
    mkdir -p airflow_service/conf/hadoop_jars

    # Download do SDK da AWS
    curl -L -o airflow_service/conf/hadoop_jars/aws-java-sdk-bundle-1.12.316.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.316/aws-java-sdk-bundle-1.12.316.jar

    # Download do conector Hadoop-AWS
    curl -L -o airflow_service/conf/hadoop_jars/hadoop-aws-3.3.4.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
    ```

-----

## INICIANDO O AMBIENTE

#### Para iniciar a plataforma, execute o script `start.sh` passando o ambiente desejado como parâmetro.

*No Linux/macOS, dê permissão de execução ao script primeiro:*

```bash
chmod +x start.sh
```

*Agora, inicie o ambiente desejado:*

```bash
# Exemplo para iniciar o ambiente de desenvolvimento
./start.sh dev

# Exemplo para iniciar o ambiente de produção
./start.sh prod

# Exemplo para o ambiente mais básico
./start.sh local
```

O script cuidará de criar a rede, iniciar o Airbyte e subir todos os outros serviços definidos para o ambiente selecionado.

-----

## TESTANDO TECNOLOGIAS ESPECÍFICAS

Caso não queira subir a stack completa, você pode iniciar apenas os serviços que deseja testar.

#### Para iniciar um ou mais serviços

Use o comando `docker compose up -d` seguido do nome dos serviços definidos no `docker-compose.yml`. Lembre-se de iniciar também suas dependências.

*Exemplo: Para testar o Apache Airflow de forma isolada (com suas dependências essenciais):*

```bash
# Sobe o banco de dados, o cache e os serviços do Airflow
docker compose up -d postgres redis airflow_init airflow_webserver airflow_scheduler
```

#### Instruções Especiais para o Airbyte

O **Airbyte** possui uma gestão de deploy separada do `docker-compose` principal, utilizando sua própria ferramenta de linha de comando, `abctl`.

O script `start.sh` **automatiza** a instalação e inicialização do Airbyte para você.

Se, no entanto, você desejar controlar o Airbyte manualmente:

1.  **Instalação (se for a primeira vez):**
    ```bash
    curl -LsfS https://get.airbyte.com | bash
    ```
2.  **Inicialização:**
    ```bash
    abctl local install
    ```

A UI do Airbyte estará disponível em `http://localhost:8000`.

-----

## SOLUCIONANDO PROBLEMAS / COMANDOS ÚTEIS

#### Para verificar os containers em execução

```bash
docker ps
```

#### Para parar um container específico

```bash
docker compose stop [nome-do-serviço]
```

#### Para parar todos os containers do projeto

```bash
docker compose down
```

#### Para remover um container específico

```bash
docker compose rm [nome-do-serviço]
```

#### Para ver os logs de um container em tempo real

```bash
docker compose logs -f [nome-do-serviço]
```

-----

## ACESSO WEBUI DOS FRAMEWORKS

  * **Airbyte:** [http://localhost:8000](https://www.google.com/search?q=http://localhost:8000)
  * **Apache Airflow:** [http://localhost:18080](https://www.google.com/search?q=http://localhost:18080)
  * **Apache Flink:** [http://localhost:8087](https://www.google.com/search?q=http://localhost:8087)
  * **Apache NiFi:** [http://localhost:8181/nifi](https://www.google.com/search?q=http://localhost:8181/nifi)
  * **Apache Spark Master:** [http://localhost:9090](https://www.google.com/search?q=http://localhost:9090)
  * **Apache Superset:** [http://localhost:8089](https://www.google.com/search?q=http://localhost:8089)
  * **CloudBeaver (DBeaver):** [http://localhost:8989](https://www.google.com/search?q=http://localhost:8989)
  * **Grafana:** [http://localhost:3000](https://www.google.com/search?q=http://localhost:3000)
  * **Jenkins:** [http://localhost:8085](https://www.google.com/search?q=http://localhost:8085)
  * **JupyterLab:** [http://localhost:9888](https://www.google.com/search?q=http://localhost:9888)
  * **Kafka Control Center:** [http://localhost:9021](https://www.google.com/search?q=http://localhost:9021)
  * **Kibana:** [http://localhost:5601](https://www.google.com/search?q=http://localhost:5601)
  * **MinIO Console:** [http://localhost:9001](https://www.google.com/search?q=http://localhost:9001)
  * **Neo4j Browser:** [http://localhost:7474](https://www.google.com/search?q=http://localhost:7474)
  * **OpenMetadata:** [http://localhost:8585](https://www.google.com/search?q=http://localhost:8585)
  * **Prometheus:** [http://localhost:19090](https://www.google.com/search?q=http://localhost:19090)
  * **Trino UI:** [http://localhost:8086](https://www.google.com/search?q=http://localhost:8086)

-----

## USUÁRIOS E SENHAS

  * **Airbyte**
      * Configurar no primeiro acesso.
  * **Apache Airflow**
      * Usuário: `airflow`
      * Senha: `airflow`
  * **Apache Superset**
      * Usuário: `admin`
      * Senha: `admin`
  * **CloudBeaver (DBeaver)**
      * Configurar no primeiro acesso.
  * **Grafana**
      * Usuário: `admin`
      * Senha: `admin`
  * **Jenkins**
      * Usuário: `admin`
      * Senha Inicial: *Execute o comando abaixo para obter a senha*
        ```bash
        docker compose logs jenkins_ci_cd | grep -A 3 'initial admin password'
        ```
  * **MinIO**
      * Usuário (Console): `admin`
      * Senha (Console): `minioadmin`
      * Access Key (API): `datalake`
      * Secret Key (API): `datalake`
  * **MongoDB**
      * Usuário: `mongoadmin`
      * Senha: `mongopassword`
  * **Neo4j**
      * Usuário: `neo4j`
      * Senha: `admin123`
  * **OpenMetadata**
      * E-mail: `admin@open-metadata.org`
      * Senha: `admin`
  * **PostgreSQL**
      * Usuário: `airflow`
      * Senha: `airflow`

-----

## IMAGENS

Para mais detalhes sobre as imagens customizadas, acesse nosso [Docker Hub](https://www.google.com/search?q=https://hub.docker.com/u/SEU-USUARIO).

-----

## DOCUMENTAÇÃO OFICIAL DOS AMBIENTES

  * [Airbyte](https://www.google.com/search?q=https://docs.airbyte.com/deploying-airbyte/on-your-local-machine)
  * [Apache Airflow](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)
  * [Apache Flink](https://nightlies.apache.org/flink/flink-docs-master/docs/deployment/resource-providers/standalone/docker/)
  * [Apache Hive](https://www.google.com/search?q=https://cwiki.apache.org/confluence/display/HIVE/Hive%2Bon%2BDocker)
  * [Apache NiFi](https://hub.docker.com/r/apache/nifi)
  * [Apache Spark](https://spark.apache.org/docs/latest/running-on-kubernetes.html)
  * [Apache Superset](https://superset.apache.org/docs/installation/installing-superset-using-docker-compose)
  * [Confluent Platform (Kafka)](https://docs.confluent.io/platform/current/installation/docker/installation.html)
  * [CloudBeaver](https://dbeaver.com/docs/cloudbeaver/Run-Docker-Container/)
  * [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)
  * [Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)
  * [Jenkins](https://www.jenkins.io/doc/book/installing/docker/)
  * [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/en/latest/index.html)
  * [Kibana](https://www.elastic.co/guide/en/kibana/current/docker.html)
  * [MinIO](https://min.io/docs/minio/container/index.html)
  * [MongoDB](https://hub.docker.com/_/mongo)
  * [Neo4j](https://neo4j.com/docs/operations-manual/current/docker/)
  * [OpenMetadata](https://docs.open-metadata.org/deployment/docker)
  * [PostgreSQL](https://hub.docker.com/_/postgres)
  * [Prometheus](https://www.google.com/search?q=https://prometheus.io/docs/prometheus/latest/installation/%23docker)
  * [Redis](https://hub.docker.com/_/redis)
  * [Trino](https://trino.io/docs/current/installation/containers.html)
