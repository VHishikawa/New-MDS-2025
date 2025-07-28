from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id='my_first_test_dag',
    start_date=datetime(2023, 1, 1),
    schedule_interval=None,  # Isso significa que não será executada automaticamente
    catchup=False,           # Não executa para datas passadas
    tags=['test'],
) as dag:
    # Primeira tarefa: Imprime "Hello Airflow!"
    start_task = BashOperator(
        task_id='print_hello',
        bash_command='echo "Hello Airflow from my first DAG!"',
    )

    # Segunda tarefa: Imprime a data atual
    end_task = BashOperator(
        task_id='print_date',
        bash_command='echo "Today is $(date)"',
    )

    # Define a ordem de execução das tarefas
    start_task >> end_task