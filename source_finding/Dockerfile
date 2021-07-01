# SoFiAX image for execution of SoFiA.
# This version is necessary because of the catalog subfolder that is
# included for this execution with default sofia parameters.

FROM ubuntu:20.04
WORKDIR /app

# Dependencies
RUN apt-get update &&\
    apt-get install -y git build-essential wcslib-dev &&\
    apt install -y libomp-dev
RUN apt update &&\
    apt install -y python3 python3-pip

# Copy files
COPY catalog catalog

# SoFiA
RUN git clone https://github.com/SoFiA-Admin/SoFiA-2.git &&\
    cd SoFiA-2 &&\
    ./compile.sh -fopenmp &&\
    mv sofia /usr/local/bin

# SoFiAX
RUN git clone https://github.com/AusSRC/SoFiAX.git &&\
    cd SoFiAX &&\
    python3 setup.py install
