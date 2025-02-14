FROM continuumio/miniconda3
COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

SHELL ["/bin/bash", "--login", "-c"]

RUN ./docker-requirements.sh

RUN mkdir /persistent


# Start the server
EXPOSE 8005
EXPOSE 8006
EXPOSE 8007
 
ENTRYPOINT [ "neural_solution" ]
CMD ["start", "--restful_api_port=8005", "--result_monitor_port=8006", "--task_monitor_port=8007", "--api_type=restful", "--conda_env=py_env", "--workspace=/persistent/ns_workspace"]

