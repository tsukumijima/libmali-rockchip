ARG IMAGE
FROM ${IMAGE}
ENV DEBIAN_FRONTEND=noninteractive
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
        libxcb-dri2-0 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libwayland-client0 && \
    rm -rf /var/lib/apt/lists/*
COPY . /src/
WORKDIR /src/
