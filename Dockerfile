##
# osgeo/gdal:ubuntu-small

# This file is available at the option of the licensee under:
# Public domain
# or licensed under X/MIT (LICENSE.TXT) Copyright 2019 Even Rouault <even.rouault@spatialys.com>

ARG PROJ_INSTALL_PREFIX=/usr/local
ARG BASE_IMAGE=ubuntu:20.04

FROM $BASE_IMAGE as builder

# Derived from osgeo/proj by Howard Butler <howard@hobu.co>
LABEL maintainer="Even Rouault <even.rouault@spatialys.com>"

# Setup build env for PROJ
USER root
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
            software-properties-common build-essential ca-certificates \
            git make cmake wget unzip libtool automake \
            zlib1g-dev libsqlite3-dev pkg-config sqlite3 libcurl4-gnutls-dev \
            libtiff5-dev

# Setup build env for GDAL
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
       python3-dev python3-numpy \
       libjpeg-dev libgeos-dev \
       libexpat-dev libxerces-c-dev \
       libwebp-dev \
       libzstd-dev bash zip curl \
       libpq-dev libssl-dev libopenjp2-7-dev \
       autoconf automake sqlite3 bash-completion

# Build openjpeg
ARG OPENJPEG_VERSION=
RUN if test "${OPENJPEG_VERSION}" != ""; then ( \
    wget -q https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz \
    && tar xzf v${OPENJPEG_VERSION}.tar.gz \
    && rm -f v${OPENJPEG_VERSION}.tar.gz \
    && cd openjpeg-${OPENJPEG_VERSION} \
    && cmake . -DBUILD_SHARED_LIBS=ON  -DBUILD_STATIC_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /build_thirdparty/usr/lib \
    && cp -P /usr/lib/libopenjp2*.so* /build_thirdparty/usr/lib \
    && for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && cd .. \
    && rm -rf openjpeg-${OPENJPEG_VERSION} \
    ); fi

ARG PROJ_INSTALL_PREFIX
ARG PROJ_DATUMGRID_LATEST_LAST_MODIFIED
RUN \
    mkdir -p /build_projgrids/${PROJ_INSTALL_PREFIX}/share/proj \
    && curl -LOs http://download.osgeo.org/proj/proj-datumgrid-latest.zip \
    && unzip -q -j -u -o proj-datumgrid-latest.zip  -d /build_projgrids/${PROJ_INSTALL_PREFIX}/share/proj \
    && rm -f *.zip

RUN apt-get update -y \
    && apt-get install -y --fix-missing --no-install-recommends rsync ccache
ARG RSYNC_REMOTE

# Build PROJ
ARG PROJ_VERSION=master
RUN mkdir proj \
    && wget -q https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz -O - \
        | tar xz -C proj --strip-components=1 \
    && cd proj \
    && ./autogen.sh \
    && if test "${RSYNC_REMOTE}" != ""; then \
        echo "Downloading cache..."; \
        rsync -ra ${RSYNC_REMOTE}/proj/ $HOME/; \
        echo "Finished"; \
        export CC="ccache gcc"; \
        export CXX="ccache g++"; \
        export PROJ_DB_CACHE_DIR="$HOME/.ccache"; \
        ccache -M 100M; \
    fi \
    && CFLAGS='-DPROJ_RENAME_SYMBOLS -O2' CXXFLAGS='-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2' \
        ./configure --prefix=${PROJ_INSTALL_PREFIX} --disable-static \
    && make -j$(nproc) \
    && make install DESTDIR="/build" \
    && if test "${RSYNC_REMOTE}" != ""; then \
        ccache -s; \
        echo "Uploading cache..."; \
        rsync -ra --delete $HOME/.ccache ${RSYNC_REMOTE}/proj/; \
        echo "Finished"; \
        rm -rf $HOME/.ccache; \
        unset CC; \
        unset CXX; \
    fi \
    && cd .. \
    && rm -rf proj \
    && PROJ_SO=$(readlink /build${PROJ_INSTALL_PREFIX}/lib/libproj.so | sed "s/libproj\.so\.//") \
    && PROJ_SO_FIRST=$(echo $PROJ_SO | awk 'BEGIN {FS="."} {print $1}') \
    && mv /build${PROJ_INSTALL_PREFIX}/lib/libproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO} \
    && ln -s libinternalproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO_FIRST} \
    && ln -s libinternalproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so \
    && rm /build${PROJ_INSTALL_PREFIX}/lib/libproj.*  \
    && ln -s libinternalproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libproj.so.${PROJ_SO_FIRST} \
    && strip -s /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO} \
    && for i in /build${PROJ_INSTALL_PREFIX}/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build GDAL
ARG GDAL_VERSION=master
ARG GDAL_RELEASE_DATE
ARG GDAL_BUILD_IS_RELEASE
ARG GDAL_REPOSITORY=OSGeo/gdal

RUN if test "${GDAL_VERSION}" = "master"; then \
        export GDAL_VERSION=$(curl -Ls https://api.github.com/repos/${GDAL_REPOSITORY}/commits/HEAD -H "Accept: application/vnd.github.VERSION.sha"); \
        export GDAL_RELEASE_DATE=$(date "+%Y%m%d"); \
    fi \
    && if test "x${GDAL_BUILD_IS_RELEASE}" = "x"; then \
        export GDAL_SHA1SUM=${GDAL_VERSION}; \
    fi \
    && mkdir gdal \
    && wget -q https://github.com/${GDAL_REPOSITORY}/archive/${GDAL_VERSION}.tar.gz -O - \
        | tar xz -C gdal --strip-components=1 \
    && cd gdal/gdal \
    && if test "${RSYNC_REMOTE}" != ""; then \
        echo "Downloading cache..."; \
        rsync -ra ${RSYNC_REMOTE}/gdal/ $HOME/; \
        echo "Finished"; \
        # Little trick to avoid issues with Python bindings
        printf "#!/bin/sh\nccache gcc \$*" > ccache_gcc.sh; \
        chmod +x ccache_gcc.sh; \
        printf "#!/bin/sh\nccache g++ \$*" > ccache_g++.sh; \
        chmod +x ccache_g++.sh; \
        export CC=$PWD/ccache_gcc.sh; \
        export CXX=$PWD/ccache_g++.sh; \
        ccache -M 1G; \
    fi \
    && LDFLAGS="-L/build${PROJ_INSTALL_PREFIX}/lib -linternalproj" ./configure --prefix=/usr --without-libtool \
    --with-hide-internal-symbols \
    --with-jpeg12 \
    --with-python \
    --with-webp --with-proj=/build${PROJ_INSTALL_PREFIX} \
    --with-libtiff=internal --with-rename-internal-libtiff-symbols \
    --with-geotiff=internal --with-rename-internal-libgeotiff-symbols \
    && make -j$(nproc) \
    && make install DESTDIR="/build" \
    && if test "${RSYNC_REMOTE}" != ""; then \
        ccache -s; \
        echo "Uploading cache..."; \
        rsync -ra --delete $HOME/.ccache ${RSYNC_REMOTE}/gdal/; \
        echo "Finished"; \
        rm -rf $HOME/.ccache; \
        unset CC; \
        unset CXX; \
    fi \
    && cd ../.. \
    && rm -rf gdal \
    && mkdir -p /build_gdal_python/usr/lib \
    && mkdir -p /build_gdal_python/usr/bin \
    && mkdir -p /build_gdal_version_changing/usr/include \
    && mv /build/usr/lib/python*            /build_gdal_python/usr/lib \
    && mv /build/usr/lib                    /build_gdal_version_changing/usr \
    && mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include \
    && mv /build/usr/bin/*.py               /build_gdal_python/usr/bin \
    && mv /build/usr/bin                    /build_gdal_version_changing/usr \
    && for i in /build_gdal_version_changing/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_version_changing/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build final image
FROM $BASE_IMAGE as runner

USER root
RUN date

# PROJ dependencies
RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        libsqlite3-0 libtiff5 libcurl4 \
        curl unzip ca-certificates

# GDAL dependencies
RUN apt-get update -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        python3-numpy libpython3.8 \
        libjpeg-turbo8 libgeos-3.8.0 libgeos-c1v5 \
        libexpat1 \
        libxerces-c3.2 \
        libwebp6 \
        libzstd1 bash libpq5 libssl1.1 libopenjp2-7

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python-is-python3

# Order layers starting with less frequently varying ones
# Only used for custom libopenjp2
# COPY --from=builder  /build_thirdparty/usr/ /usr/

COPY --from=builder  /build_projgrids/usr/ /usr/

ARG PROJ_INSTALL_PREFIX
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/share/proj/ ${PROJ_INSTALL_PREFIX}/share/proj/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/include/ ${PROJ_INSTALL_PREFIX}/include/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/bin/ ${PROJ_INSTALL_PREFIX}/bin/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/lib/ ${PROJ_INSTALL_PREFIX}/lib/

COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_python/usr/ /usr/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

RUN ldconfig

#############################################################################
# END OF GDAL INSTRUCTIONS
# MINTPY INSTRUCTIONS FROM HERE DOWN
#############################################################################

RUN apt-get update && \
    apt-get install -y \
    git \
    python3 \
    python3-pip \
    wget \
    vim \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Change default shell from dash to bash permanently
# RUN ln -sf bash /bin/sh

# Prepare build time environment for conda and mintpy
ARG MINTPY_HOME=/home/python/MintPy
ARG PYTHON3DIR=/home/python/miniconda3
ARG PYAPS_HOME=/home/python/PyAPS
ARG WORK_DIR=/home/work/

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
RUN wget https://repo.continuum.io/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh && \
    chmod +x ./Miniconda3-4.5.4-Linux-x86_64.sh  && \
    ./Miniconda3-4.5.4-Linux-x86_64.sh -b -p ${PYTHON3DIR} && \
    rm ./Miniconda3-4.5.4-Linux-x86_64.sh

# Install dependencies
COPY ["conda.txt", "/tmp/conda.txt"]
RUN ${PYTHON3DIR}/bin/conda config --add channels conda-forge && \
    ${PYTHON3DIR}/bin/conda install --yes --file /tmp/conda.txt

# RUN ${PYTHON3DIR}/bin/conda config --add channels conda-forge && \
#     ${PYTHON3DIR}/bin/conda install --yes --file ${MINTPY_HOME}/docs/conda.txt

# Install pykml
RUN ${PYTHON3DIR}/bin/pip install git+https://github.com/yunjunz/pykml.git

# Install DASK - not tested yet
#RUN mkdir -p /home/.config/dask && \
#    cp ${MINTPY_HOME}/mintpy/defaults/dask_mintpy.yaml /home/.config/dask/dask_mintpy.yaml

# Set working directory ENV - map a host data volume to this using "docker build . -t mintpy && docker run mintpy -v /host/path/to/data:/home/work/"
RUN mkdir -p ${WORK_DIR}
ENV WORK_DIR=${WORK_DIR}
WORKDIR ${WORK_DIR}
