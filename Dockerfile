FROM debian:buster as builder

# heavily influenced by https://gist.github.com/Brainiarc7/3f7695ac2a0905b05c5b
# but here now as a container

RUN mkdir -p ~/ffmpeg_source && apt update && apt upgrade && \
    apt install -y git-core gnupg curl software-properties-common \
    nasm autoconf automake build-essential libtool libass-dev \
    libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev \
    libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev \
    libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texi2html 

# Install Cuda SDK
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/debian10/x86_64/7fa2af80.pub && \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/debian10/x86_64/ /" && \
    add-apt-repository contrib && apt-get update && apt-get -y install cuda-libraries-dev-11-1 cuda-compiler-11-1

# Install Nvidia NVENC SDK
RUN cd ~/ffmpeg_source && \
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && make -j $(nproc) && make -j$(nproc) install

# Install x264
RUN cd ~/ffmpeg_source && git clone https://code.videolan.org/videolan/x264.git && \
    cd x264 && git checkout stable && \
    PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static && \
    PATH="$HOME/bin:$PATH" make -j$(nproc) && make -j$(nproc) install

# install aac
RUN cd ~/ffmpeg_source && git clone https://github.com/mstorsjo/fdk-aac.git && \
    cd fdk-aac && git fetch --all --tags && git checkout tags/v2.0.1 && \
    autoreconf -fiv && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
    make -j$(nproc) && make -j$(nproc) install

# install opus
RUN cd ~/ffmpeg_source && curl -LO https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
    tar xzf opus-1.3.1.tar.gz && cd opus-1.3.1 && \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
    make -j$(nproc) && make -j$(nproc) install

# install vpX codecs from google
RUN cd ~/ffmpeg_source && git clone https://chromium.googlesource.com/webm/libvpx && \
    cd libvpx && \
    PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 \
--enable-postproc --enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility --enable-vp9-highbitdepth --enable-onthefly-bitpacking --enable-realtime-only \
--cpu=native --as=nasm && \
    PATH="$HOME/bin:$PATH" make -j$(nproc) && \
    make -j$(nproc) install

# now compile ffmpeg
RUN cd ~/ffmpeg_source && git clone https://github.com/FFmpeg/FFmpeg && \
    cd FFmpeg && ./configure && make -j$(nproc) && make -j$(nproc) install
