FROM debian:bookworm-slim

LABEL author="pao2pao16"
LABEL org.opencontainers.image.source="https://github.com/pao2pao16/pz-steamcmd"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt update \
    && apt upgrade -y \
    && apt install -y \
        curl \
        gpg \
        g++ \
        gcc \
        gdb \
        iproute2 \
        locales \
        net-tools \
        netcat-traditional \
        tar \
        telnet \
        tini \
        tzdata \
        wget \
        xvfb \
        lib32gcc-s1 \
        lib32stdc++6 \
        lib32tinfo6 \
        lib32z1 \
        libcurl3-gnutls:i386 \
        libcurl4-gnutls-dev:i386 \
        libcurl4:i386 \
        libfontconfig1 \
        libgcc-11-dev \
        libgcc-12-dev \
        libncurses5:i386 \
        libsdl1.2debian \
        libsdl2-2.0-0 \
        libsdl2-2.0-0:i386 \
        libssl-dev:i386 \
        libtinfo6:i386 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp/ \
    && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
    && tar xvf rcon.tar.gz \
    && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/ \
    && rm -rf /tmp/*

RUN if [ "$(uname -m)" = "x86_64" ]; then \
        wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
        dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd
