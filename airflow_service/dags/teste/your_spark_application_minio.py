import pyspark
from delta import *
from delta.tables import *
from pyspark.sql.functions import *

builder = pyspark.sql.SparkSession.builder.appName("delta").master("spark://spark-master:7077") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .config("spark.hadoop.fs.s3a.access.key","datalake") \
    .config("spark.hadoop.fs.s3a.secret.key","datalake") \
    .config("spark.hadoop.fs.s3a.endpoint","http://minio:9000") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.driver.extraClassPath", "/opt/spark/jars/*") \
    .config("spark.executor.extraClassPath", "/opt/spark/jars/*")

spark = configure_spark_with_delta_pip(builder).enableHiveSupport().getOrCreate()

# Local do arquivo no MinIO
file_location = "s3a://bronze/Dados.csv"

# Configurando CSV
infer_schema = "false"
first_row_is_header = "True"
delimiter = ","

# Cria o dataframe a partir do arquivo CSV
df_partidas = spark.read.format('csv') \
 .option("inferSchema", infer_schema) \
 .option("header", first_row_is_header) \
 .option("sep", delimiter) \
 .load(file_location)

# Retorna a quantidade de linhas e imprime para o log do Airflow
num_linhas = df_partidas.count()
print(f"Total de linhas no arquivo: {num_linhas}")

spark.stop()