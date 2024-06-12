FROM debian:bullseye-slim

LABEL maintainer="Brett - github.com/brettmayson"
LABEL org.opencontainers.image.source=https://github.com/brettmayson/arma3server

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN sed 's/main/main contrib non-free/g' /etc/apt/sources.list > /tmp/sources.list \
    && cp /tmp/sources.list /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && apt update \
    && apt install -y --no-install-recommends --no-install-suggests \
        python3 \
        python3-bs4 \
        lib32stdc++6 \
        lib32gcc-s1 \
        wget \
        ca-certificates \
        steamcmd \
    && apt remove --purge -y \
    && apt clean autoclean \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Update SteamCMD and verify latest version
RUN steamcmd +quit \ && mkdir -p $HOME/.steam

# Fix missing directories and libraries
RUN ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32 \
    && ln -s $HOME/.local/share/Steam/steamcmd/linux64 $HOME/.steam/sdk64 \
    && ln -s $HOME/.steam/sdk32/steamclient.so $HOME/.steam/sdk32/steamservice.so \
    && ln -s $HOME/.steam/sdk64/steamclient.so $HOME/.steam/sdk64/steamservice.so

ENV ARMA_BINARY=./arma3server_x64
ENV ARMA_CONFIG=main.cfg
ENV ARMA_PROFILE=main
ENV ARMA_WORLD=empty
ENV ARMA_LIMITFPS=1000
ENV ARMA_PARAMS=
ENV ARMA_CDLC=
ENV HEADLESS_CLIENTS=0
ENV PORT=2302
ENV STEAM_BRANCH=public
ENV STEAM_BRANCH_PASSWORD=
ENV MODS_LOCAL=true
ENV MODS_PRESET=

EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
EXPOSE 2306/udp

VOLUME /arma3

WORKDIR /arma3

VOLUME /steamcmd

STOPSIGNAL SIGINT

COPY *.py /

CMD ["python3","/launch.py"]
