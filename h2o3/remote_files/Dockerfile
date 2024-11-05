########################################################################
# Dockerfile for Oracle JDK 8 on Ubuntu 16.04
########################################################################

# pull base image
FROM ubuntu:16.04

# maintainer details
MAINTAINER h2oai "h2o.ai"

# add a post-invoke hook to dpkg which deletes cached deb files
# update the sources.list
# update/dist-upgrade
# clear the caches


RUN \
  echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache && \
  echo "deb http://mirror.math.princeton.edu/pub/ubuntu xenial main universe" >> /etc/apt/sources.list && \
  apt-get update -q -y && \
  apt-get dist-upgrade -y && \
  apt-get clean && \
  rm -rf /var/cache/apt/* && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip openjdk-8-jdk python-pip python-sklearn python-pandas python-numpy python-matplotlib software-properties-common python-software-properties && \
  apt-get clean

# this is necessary because the pip version installed (8.1.1) is too old
RUN \
  wget https://bootstrap.pypa.io/pip/2.7/get-pip.py -O get-pip.py && \
  python get-pip.py  && \ 
  rm get-pip.py
RUN ln -s $(which pip) /usr/bin/pip

# Fetch h2o latest_stable
RUN \
  wget http://h2o-release.s3.amazonaws.com/h2o/latest_stable -O latest && \
  wget -i latest -O /opt/h2o.zip && \
  unzip -d /opt /opt/h2o.zip && \
  rm /opt/h2o.zip && \
  cd /opt && \
  cd `find . -name 'h2o.jar' | sed 's/.\///;s/\/h2o.jar//g'` && \
  cp h2o.jar /opt && \
  /usr/bin/pip install `find . -name "*.whl"` && \
  printf '!/bin/bash\ncd /home/h2o\n./start-h2o-docker.sh\n' > /start-h2o-docker.sh && \
  chmod +x /start-h2o-docker.sh

RUN \
  useradd -m -c "h2o.ai" h2o

USER h2o

# Get Content
RUN \
  cd && \
  wget https://raw.githubusercontent.com/h2oai/h2o-3/master/docker/start-h2o-docker.sh && \
  chmod +x start-h2o-docker.sh 
  # && \
  # this gives a 403. no idea why the dockerfile is so broken
  # wget http://s3.amazonaws.com/h2o-training/mnist/train.csv.gz && \
  # gunzip train.csv.gz

# Define a mountable data directory
#VOLUME \
#  ["/data"]

# Define the working directory
WORKDIR \
  /home/h2o

EXPOSE 54321
EXPOSE 54322

# ENTRYPOINT ["java", "-Xmx4g", "-jar", "/opt/h2o.jar"]
# Define default command

# CMD \
#   ["/bin/bash"]
# CMD ["bash", "-c", "while true; do sleep 1000; done"]
CMD ["java", "-Xmx4g", "-jar", "/opt/h2o.jar"]
