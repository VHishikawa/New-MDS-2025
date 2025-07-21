#!/bin/bash
set -e

# Garante que o SPARK_HOME esteja configurado
# REMOVIDO: export SPARK_HOME=/spark (Esta linha sobrescrevia a configuracao do Dockerfile)
# O SPARK_HOME é definido via ENV no Dockerfile para /opt/spark
# Para referencia, Spark será encontrado em /opt/spark
export PATH=$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 # Garante JAVA_HOME aqui também

# Verifica o argumento passado para o container
if [ "$1" = "master" ]; then
  echo "Iniciando Spark Master..."
  # Inicia o Spark History Server para visualizar logs de aplicações finalizadas
  # Garanta que SPARK_HOME esteja correto para este caminho
  ${SPARK_HOME}/sbin/start-history-server.sh
  # Inicia o Spark Master em foreground
  ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.master.Master -h $HOSTNAME
elif [ "$1" = "worker" ]; then
  echo "Iniciando Spark Worker..."
  # Inicia o Spark Worker e conecta-o ao master
  ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
elif [ "$1" = "notebook" ]; then
  echo "Iniciando JupyterLab com Spark..."
  # Inicia o JupyterLab na porta 8888, sem token e apontando para a pasta de notebooks
  jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.password='' --notebook-dir=/opt/spark-notebooks
else
  echo "Comando desconhecido: $@"
  exec "$@"
fi