FROM python:3.9.13-bullseye

WORKDIR /app

RUN echo "deb-src http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian-security/ bullseye-security main" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian bullseye-updates main" >> /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y python3-dev \
    && apt-get build-dep -y python3 \
    && apt-get install -y \
        build-essential gdb lcov pkg-config \
        libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
        libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
        lzma lzma-dev tk-dev uuid-dev zlib1g-dev

RUN curl https://www.python.org/ftp/python/3.9.13/Python-3.9.13.tar.xz -o python.tar.xz \
    && tar xf python.tar.xz \
    && mv Python-3.9.13 build-python

RUN mkdir cross-python
RUN ln -s /usr/bin/readelf /usr/bin/arm-linux-gnueabihf-readelf

RUN PATH=./build-python/bin:$PATH \
    CC=gcc \
    cd build-python; \
    ./configure --prefix="/app/cross-python" \
    --host=arm-linux-gnueabihf \
    --build=x86_64-linux-gnu \
    ac_cv_buggy_getaddrinfo=no \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    --enable-optimizations

RUN cd build-python; nice -n -19 make -j && make -j install

RUN /app/cross-python/bin/python3 -m ensurepip --upgrade \
    && /app/cross-python/bin/python3 -m pip install --upgrade pip \
    && /app/cross-python/bin/python3 -m pip install --upgrade setuptools \
    && /app/cross-python/bin/python3 -m pip install install crossenv \
    && /app/cross-python/bin/python3 -m crossenv cross-python/bin/python3 venv

ENTRYPOINT ["bash"]
