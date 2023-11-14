ARG IMAGE
FROM ${IMAGE}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntu-support-team/meson
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        debhelper \
        devscripts \
        meson \
        pkg-config \
        libstdc++6 \
        libgbm-dev \
        libdrm-dev \
        libx11-6 \
        libx11-dev \
        libx11-xcb1 \
        libx11-xcb-dev \
        libxcb-dri2-0 \
        libxcb-dri2-0-dev \
        libxdamage1 \
        libxdamage-dev \
        libxext6 \
        libxext-dev \
        libxfixes3 \
        libxfixes-dev \
        libwayland-client0 \
        libwayland-dev && \
    rm -rf /var/lib/apt/lists/*
COPY . /src/
WORKDIR /src/
