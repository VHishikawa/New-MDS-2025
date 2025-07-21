from __future__ import annotations

import pendulum

from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id='dag_dbt_exemplo',
    start_date=pendulum.datetime(2025, 7, 2, tz="UTC"),
    schedule=None,
    catchup=False,
    tags=['dbt', 'exemplo'],
) as dag:
    
    # Tarefa que executa 'dbt run'. Ela irá rodar todos os modelos na sua pasta 'models'.
    dbt_run = BashOperator(
        task_id='dbt_executar_modelos',
        bash_command='dbt run --project-dir /opt/airflow/dbt_project --profiles-dir /home/airflow/.dbt'
    )

    # Tarefa que executa 'dbt test'. Ela irá rodar todos os testes que você definir.
    dbt_test = BashOperator(
        task_id='dbt_testar_modelos',
        bash_command='dbt test --project-dir /opt/airflow/dbt_project --profiles-dir /home/airflow/.dbt'
    )

    # Define a ordem de execução: primeiro roda, depois testa.
    dbt_run >> dbt_test