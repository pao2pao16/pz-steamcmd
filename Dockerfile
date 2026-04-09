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

RUN curl -sSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
       > /etc/apt/sources.list.d/adoptium.list \
    && apt update \
    && apt install -y temurin-25-jre \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/temurin-25-jre-amd64

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
