# new_mds/airflow_service/dags/your_spark_application.py

from pyspark.sql import SparkSession

if __name__ == "__main__":
    spark = SparkSession.builder \
        .appName("SimpleSparkApplication") \
        .getOrCreate()

    data = [("Alice", 1), ("Bob", 2), ("Charlie", 3)]
    df = spark.createDataFrame(data, ["Name", "Value"])

    print("--- Spark Application Started ---")
    df.show()
    print("--- Spark Application Finished ---")

    spark.stop()