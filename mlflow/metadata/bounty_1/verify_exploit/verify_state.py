import mlflow

all_runs = mlflow.search_runs(search_all_experiments=True)
print(all_runs)
