from __future__ import annotations

import pendulum

from airflow.models.dag import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator

with DAG(
    dag_id="spark_minio_line_count",
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"),
    catchup=False,
    schedule=None,
    tags=["spark", "minio", "delta"],
) as dag:
    submit_spark_job = SparkSubmitOperator(
        task_id="submit_spark_job",
        application="/opt/airflow/dags/your_spark_application_minio.py",
        conn_id="spark_default",
        conf={
            "spark.driver.extraJavaOptions": "-Dcom.amazonaws.services.s3.enableV4",
            "spark.executor.extraJavaOptions": "-Dcom.amazonaws.services.s3.enableV4",
            "spark.hadoop.fs.s3a.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider",
            # **NOVO: Adicionando extraClassPath diretamente na DAG**
            "spark.driver.extraClassPath": "/opt/spark/jars/s3a/*",
            "spark.executor.extraClassPath": "/opt/spark/jars/s3a/*",
        },
        packages="io.delta:delta-spark_2.12:3.1.0",
    )