# syntax=docker/dockerfile:1

# Specify the architecture at build time: mipsis32r2el/armv7hf/aarch64
# Should be used for getting API image
# Currently, only armv7hf is supported
ARG ARCH=aarch64
ARG REPO=axisecp
ARG SDK_VERSION=1.10
ARG UBUNTU_VERSION=22.04

FROM arm32v7/ubuntu:${UBUNTU_VERSION} as runtime-image-armv7hf
FROM arm64v8/ubuntu:${UBUNTU_VERSION} as runtime-image-aarch64

FROM ${REPO}/acap-computer-vision-sdk:${SDK_VERSION}-${ARCH}-runtime AS cv-sdk-runtime
FROM ${REPO}/acap-computer-vision-sdk:${SDK_VERSION}-${ARCH}-devel AS cv-sdk-devel

# Setup proxy configuration
ARG HTTP_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTP_PROXY}

ENV DEBIAN_FRONTEND=noninteractive

## Install dependencies
ARG ARCH
RUN <<EOF
apt-get update
apt-get install -y -f make pkg-config libglib2.0-dev libsystemd0 tesseract-ocr libtesseract-dev liblept5 libleptonica-dev libicu-dev libpango1.0-dev libcairo2-dev libpng-dev libjpeg8-dev libgif-dev libgif7 libtiff5-dev libgomp1 zlib1g-dev libjbig-dev libjbig0 libwebpdemux2 libwebp7 libwebp-dev libarchive-dev libcurl4-openssl-dev libdeflate0 libopenjp2-7
EOF

RUN <<EOF
# cd /axis/tesseract/usr/lib/arm-linux-gnueabihf
cd /axis/tesseract/usr/lib/aarch64-linux-gnu
ln -s libgif.so.7 libgif.so
ln -s libwebp.so.7 libwebp.so
ln -s libwebpmux.so.3 libwebpmux.so
ln -s libopenjp2.so.7 libopenjp2.so
EOF

RUN <<EOF
if [ ${ARCH} = armv7hf ]; then
    apt-get install -y -f g++-arm-linux-gnueabihf
    dpkg --add-architecture armhf
    apt-get update
    apt-get install -y libglib2.0-dev:armhf libsystemd0:armhf
elif [ ${ARCH} = aarch64 ]; then
    apt-get install -y -f g++-aarch64-linux-gnu
    dpkg --add-architecture arm64
    apt-get update
    apt-get install -y libglib2.0-dev:arm64 libsystemd0:arm64
else
    printf "Error: '%s' is not a valid value for the ARCH variable\n", ${ARCH}
    exit 1
fi
EOF

COPY app/Makefile /build/
COPY app/src/ /build/src/
WORKDIR /build

RUN <<EOF
if [ ${ARCH} = armv7hf ]; then
    make CXX=arm-linux-gnueabihf-g++ CC=arm-linux-gnueabihf-gcc STRIP=arm-linux-gnueabihf-strip
elif [ ${ARCH} = aarch64 ]; then
    make  CXX=/usr/bin/aarch64-linux-gnu-g++ CC=/usr/bin/aarch64-linux-gnu-gcc STRIP=aarch64-linux-gnu-strip
else
    printf "Error: '%s' is not a valid value for the ARCH variable\n", ${ARCH}
    exit 1
fi
EOF

FROM runtime-image-${ARCH}
COPY --from=cv-sdk-devel /build/capture_app /usr/bin/
COPY --from=cv-sdk-runtime /axis/opencv /
COPY --from=cv-sdk-runtime /axis/openblas /
COPY --from=cv-sdk-runtime /axis/tesseract /

ADD https://github.com/tesseract-ocr/tessdata_fast/raw/main/eng.traineddata /tessdata/eng.traineddata
ENV TESSDATA_PREFIX=/tessdata

CMD ["/usr/bin/capture_app"]
