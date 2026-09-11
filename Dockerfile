FROM ghcr.io/cirruslabs/flutter:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    libsecret-1-dev \
    libjsoncpp-dev \
    libglu1-mesa \
    mesa-utils \
    libasound2-dev \
    libpulse-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

CMD ["bash"]