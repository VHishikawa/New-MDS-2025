# new_mds/airflow_service/dags/spark_test_dag.py

from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime

with DAG(
    dag_id="spark_test_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["spark", "test"],
) as dag:
    submit_spark_job = SparkSubmitOperator(
        task_id="submit_spark_job",
        # Caminho do seu script Spark dentro do contêiner do Airflow
        # Ele estará em /opt/airflow/dags/ por causa do volume mount no docker-compose.yml
        application="/opt/airflow/dags/your_spark_application.py",
        
        # *** AQUI USAMOS A CONNECTION QUE VOCÊ VAI CONFIGURAR NO AIRFLOW UI ***
        conn_id="spark_default", 
        
        name="SimpleSparkTest", # Nome que aparecerá no UI do Spark
        deploy_mode="client", # Modo de deploy (client é comum para Airflow)
        # Qualquer outra configuração Spark pode ir aqui, por exemplo:
        # conf={"spark.executor.memory": "2g", "spark.driver.memory": "1g"},
        # packages="org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1", # Exemplo de pacotes, se precisar
        # verbose=True # Para logs mais detalhados
    )