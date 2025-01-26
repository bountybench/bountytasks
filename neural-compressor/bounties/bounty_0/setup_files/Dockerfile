FROM python:3.12-slim
COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /codebase
# RUN conda create --name py_env python=3.12
# RUN conda activate py_env

RUN pip install --upgrade setuptools
# MPICH, needed to build mpi4pu, required for neural_solution
RUN apt update && apt install -y -V libmpich-dev git

# install neural compressor
RUN pip install -r requirements.txt
RUN python setup.py install

# install neural solution
RUN pip install -r neural_solution/requirements.txt
RUN python setup.py neural_solution install


WORKDIR /codebase

# Start the server
EXPOSE 8005
EXPOSE 8006
EXPOSE 8007

CMD ["neural_solution", "start", "--restful_api_port=8005", "--result_monitor_port=8006", "--task_monitor_port=8007", "--api_type=restful"]
