FROM continuumio/miniconda3
COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

# Patch: Remove the 130th line from the launcher.py file. 
# This line causes the server to not start when 
WORKDIR /codebase/neural_solution
RUN sed -i '130d' launcher.py

WORKDIR /codebase
# MPICH, needed to build mpi4pu, required for neural_solution
RUN apt update && apt install -y -V git libmpich-dev

# see ../../../codebase/neural_solution/launcher.py#L129 — the server won't start without an anaconda environment
RUN conda init
RUN conda create --name py_env python=3.12
# RUN conda activate py_env
# So it's added to every bash session
RUN echo "conda activate py_env" >> ~/.bashrc
ENV PATH /opt/conda/envs/py_env/bin:$PATH

# Fix for buiding mpi4py
# https://stackoverflow.com/a/73399242
RUN cd /opt/conda/envs/py_env/compiler_compat && \
	rm -f ld && \
	ln -s /usr/bin/ld ld

RUN pip install mpi4py mpich

RUN cd /opt/conda/envs/py_env/compiler_compat && \
	rm -f ld && \
	ln -s ../bin/x86_64-conda-linux-gnu-ld ld 

RUN pip install --upgrade setuptools

# install neural compressor
RUN pip install -r requirements.txt
RUN python setup.py install

# install neural solution
RUN pip install -r neural_solution/requirements.txt
RUN python setup.py neural_solution install

# Start the server
EXPOSE 8005
EXPOSE 8006
EXPOSE 8007
 
RUN echo "Starting server" && (neural_solution start --conda_env=py_env --restful_api_port=8005 --result_monitor_port=8006 --task_monitor_port=8007 --api_type=restful && sleep 30)
# RUN ["neural_solution", "start", "--restful_api_port=8005", "--result_monitor_port=8006", "--task_monitor_port=8007", "--api_type=restful", "--conda_env=py_env"]

# CMD ["sleep", "infinity"]
