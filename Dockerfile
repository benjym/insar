# use debian as base image
# FROM debian:stretch
FROM ubuntu:21.04

# Label image
LABEL \
    "Description"="Container for open source time series InSAR processing with Mintpy" \
    "Github Source"="https://github.com/insarlab/MintPy/" \
    "Installation"="https://github.com/insarlab/MintPy/blob/master/docs/installation.md" \
    "Dockerfile Author"="Andre Theron" \
    "Email"="andretheronsa@gmail.com"

# Install useful programs
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    python3 \
    python3-pip \
    wget \
    vim \
    zip \
    libgdal-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Change default shell from dash to bash permanently
RUN ln -sf bash /bin/sh

# Prepare build time environment for conda and mintpy
ARG MINTPY_HOME=/home/python/MintPy
ARG PYTHON3DIR=/home/python/miniconda3
ARG PYAPS_HOME=/home/python/PyAPS
ARG WORK_DIR=/home/work/
ARG MINICONDA_VERSION=Miniconda3-py38_4.9.2-Linux-x86_64.sh
# ARG MINICONDA_VERSION=Miniconda3-4.5.4-Linux-x86_64.sh

# Prepare container environment
ENV MINTPY_HOME=${MINTPY_HOME}
ENV PYTHON3DIR=${PYTHON3DIR}
ENV PYAPS_HOME=${PYAPS_HOME}
ENV PATH=${MINTPY_HOME}/mintpy:${MINTPY_HOME}/sh:${PYTHON3DIR}/bin:${PATH}
ENV PYTHONPATH=${PYTHONPATH}:${MINTPY_HOME}:${PYAPS_HOME}
ENV PROJ_LIB=${PYTHON3DIR}/share/proj

# Set workdir
WORKDIR /home/python

# Pull and config mintpy
RUN git clone https://github.com/insarlab/MintPy.git

# Pull and config PyAPS
RUN git clone https://github.com/yunjunz/pyaps3.git PyAPS

# Install miniconda
RUN wget https://repo.continuum.io/miniconda/${MINICONDA_VERSION} && \
    chmod +x ./${MINICONDA_VERSION}  && \
    ./${MINICONDA_VERSION} -b -p ${PYTHON3DIR} && \
    rm ./${MINICONDA_VERSION}

# Install dependencies
RUN ${PYTHON3DIR}/bin/conda config --add channels conda-forge && \
    ${PYTHON3DIR}/bin/conda install --yes --file ${MINTPY_HOME}/docs/conda.txt

# Install hyp3 dependencies
RUN ${PYTHON3DIR}/bin/conda install gdal
RUN ${PYTHON3DIR}/bin/python -m pip install hyp3_sdk hyp3lib

# Install pykml
RUN ${PYTHON3DIR}/bin/pip install git+https://github.com/yunjunz/pykml.git

# Install DASK - not tested yet
#RUN mkdir -p /home/.config/dask && \
#    cp ${MINTPY_HOME}/mintpy/defaults/dask_mintpy.yaml /home/.config/dask/dask_mintpy.yaml

# Set working directory ENV - map a host data volume to this using "docker build . -t mintpy && docker run mintpy -v /host/path/to/data:/home/work/"
RUN mkdir -p ${WORK_DIR}
ENV WORK_DIR=${WORK_DIR}
WORKDIR ${WORK_DIR}

# Copy custom app scripts to app folder - not required
COPY ["./", "/home/app/"]

# Run entrypoint script - not required
CMD ["python3", "/home/app/app.py"]
