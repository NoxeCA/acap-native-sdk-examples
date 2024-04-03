ARG ARCH=armv7hf
#ARG ARCH=aarch64
ARG REPO=axisecp
ARG SDK=acap-native-sdk
ARG UBUNTU_VERSION=22.04
ARG VERSION=1.13

FROM ${REPO}/${SDK}:${VERSION}-${ARCH}-ubuntu${UBUNTU_VERSION}

# Set general arguments
ARG ARCH
ARG SDK_LIB_PATH_BASE=/opt/axis/acapsdk/sysroots/${ARCH}/usr
ARG BUILD_DIR=/opt/build

#-------------------------------------------------------------------------------
# Prepare build environment
#-------------------------------------------------------------------------------

# Install build dependencies for cross compiling OpenCV, Tesseract and Leptonica
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y -f --no-install-recommends \
    automake \
    autoconf \
    libtool \
    pkg-config \
    cmake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#-------------------------------------------------------------------------------
# Build OpenCV libraries
#-------------------------------------------------------------------------------

ARG OPENCV_VERSION=4.9.0
ARG OPENCV_DIR=${BUILD_DIR}/opencv
ARG OPENCV_SRC_DIR=${OPENCV_DIR}/opencv-${OPENCV_VERSION}
ARG OPENCV_BUILD_DIR=${OPENCV_DIR}/build

WORKDIR ${OPENCV_DIR}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz | tar -xz

WORKDIR ${OPENCV_BUILD_DIR}
ENV COMMON_CMAKE_FLAGS="-S $OPENCV_SRC_DIR \
        -B $OPENCV_BUILD_DIR \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D WITH_OPENEXR=OFF \
        -D WITH_GTK=OFF \
        -D WITH_V4L=OFF \
        -D WITH_FFMPEG=OFF \
        -D WITH_GSTREAMER=OFF \
        -D WITH_GSTREAMER_0_10=OFF \
        -D BUILD_LIST=core,imgproc,video \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_OPENCV_APPS=OFF \
        -D BUILD_DOCS=OFF \
        -D BUILD_JPEG=ON \
        -D BUILD_PNG=OFF \
        -D WITH_JASPER=OFF \
        -D BUILD_PROTOBUF=OFF \
        -D OPENCV_GENERATE_PKGCONFIG=ON "

# hadolint ignore=SC2086
RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        # Configure build with CMake
        cmake \
        -D CMAKE_CXX_COMPILER=${CXX%-g++*}-g++ \
        -D CMAKE_CXX_FLAGS="${CXX#*-g++}" \
        -D CMAKE_C_COMPILER=${CC%-gcc*}-gcc \
        -D CMAKE_C_FLAGS="${CC#*-gcc}" \
        -D CMAKE_TOOLCHAIN_FILE=${OPENCV_SRC_DIR}/platforms/linux/arm-gnueabi.toolchain.cmake \
        -D CPU_BASELINE=NEON,VFPV3 \
        -D ENABLE_NEON=ON \
        -D ENABLE_VFPV3=ON \
        $COMMON_CMAKE_FLAGS && \
        # Build and install OpenCV
        make -j "$(nproc)" install ; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        # Configure build with CMake
        # No need to set NEON and VFP for aarch64 since they are implicitly
        # present in an any standard armv8-a implementation.
        cmake \
        -D CMAKE_CXX_COMPILER=${CXX%-g++*}-g++ \
        -D CMAKE_CXX_FLAGS="${CXX#*-g++}" \
        -D CMAKE_C_COMPILER=${CC%-gcc*}-gcc \
        -D CMAKE_C_FLAGS="${CC#*-gcc}" \
        -D CMAKE_TOOLCHAIN_FILE=${OPENCV_SRC_DIR}/platforms/linux/aarch64-gnu.toolchain.cmake \
        $COMMON_CMAKE_FLAGS && \
        # Build and install OpenCV
        make -j "$(nproc)" install ; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

#-------------------------------------------------------------------------------
# Copy the built library files to application directory
#-------------------------------------------------------------------------------

WORKDIR /opt/app
COPY ./app .
RUN mkdir lib && \
    cp -P ${OPENCV_BUILD_DIR}/lib/lib*.so* ./lib/

#-------------------------------------------------------------------------------
# Build libjpeg-turbo libraries
#-------------------------------------------------------------------------------

WORKDIR /opt/build
RUN git clone --branch 3.0.2 https://github.com/libjpeg-turbo/libjpeg-turbo.git

WORKDIR /opt/build/libjpeg-turbo/build
RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc cmake -G"Unix Makefiles" .. && \
        make -j; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc cmake -G"Unix Makefiles" .. && \
        make -j; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

#-------------------------------------------------------------------------------
# Copy the built library files to application directory
#-------------------------------------------------------------------------------

ARG BUILD_DIR_JPEG=/opt/build/libjpeg-turbo
WORKDIR /opt/app/lib
RUN cp ${BUILD_DIR_JPEG}/build/*.so* .
RUN cp ${BUILD_DIR_JPEG}/build/*.so* ${SDK_LIB_PATH_BASE}/lib

WORKDIR /opt/app/include
RUN cp ${BUILD_DIR_JPEG}/build/*.h . && \
    cp ${BUILD_DIR_JPEG}/*.h .

WORKDIR /opt/app
COPY ./app .

#-------------------------------------------------------------------------------
# Build webp libraries
#-------------------------------------------------------------------------------

WORKDIR /opt/build
ARG WEBP_VERSION=1.2.2
RUN curl -fsSL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$WEBP_VERSION.tar.gz | tar -xz
RUN ls /opt/build
RUN mkdir /opt/build/libwebp-$WEBP_VERSION/build

WORKDIR /opt/build/libwebp-$WEBP_VERSION/build
RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi


##-------------------------------------------------------------------------------
## Build jpeg libraries
##-------------------------------------------------------------------------------
#
## Source https://www.ridgesolutions.ie/index.php/2013/05/15/cross-compiling-libjpeg-for-linux-on-arm/
#ARG JPEG_VERSION=9f
#ARG JPEG_DIR=${BUILD_DIR}/jpeg
#ARG JPEG_SRC_DIR=${JPEG_DIR}/jpeg-${JPEG_VERSION}
#ARG JPEG_BUILD_DIR=${JPEG_DIR}/build
#
#WORKDIR ${JPEG_DIR}
#RUN curl -fsSL http://www.ijg.org/files/jpegsrc.v${JPEG_VERSION}.tar.gz|tar -xz
#
#WORKDIR ${JPEG_SRC_DIR}
#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./configure --host=${ARCH} --prefix=${SDK_LIB_PATH_BASE} cc=${CC%-gcc*}-gcc
#RUN make -j "$(nproc)" && \
#    make install

#-------------------------------------------------------------------------------
# Build libtiff libraries
#-------------------------------------------------------------------------------

WORKDIR /opt/build
RUN #git clone --branch v4.6.0 https://gitlab.com/libtiff/libtiff
RUN git clone --branch v4.5.1 https://gitlab.com/libtiff/libtiff

#WORKDIR /opt/build/libtiff

#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./autogen.sh && \
#    ./configure --host=${ARCH} --prefix=${SDK_LIB_PATH_BASE} cc=${CC%-gcc*}-gcc
#RUN make -j "$(nproc)" && \
#    make install
#
#RUN tree .

WORKDIR /opt/build/libtiff/build

#RUN grep -nri J12SAMPARRAY /opt/build/libjpeg-turbo/
#        -D JPEG_INCLUDE_DIR=/opt/build/libjpeg-turbo && \
#-D CMAKE_INCLUDE_PATH=/opt/app/include && \

RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

#-------------------------------------------------------------------------------
# Copy the built library files to application directory
#-------------------------------------------------------------------------------

# Copy the built libraries to application folder
ARG BUILD_DIR_TIFF=/opt/build/libtiff
WORKDIR /opt/app/lib
RUN cp ${BUILD_DIR_TIFF}/build/libtiff/*.so* .
RUN cp ${BUILD_DIR_TIFF}/build/libtiff/*.so* ${SDK_LIB_PATH_BASE}/lib

WORKDIR /opt/app/include
RUN cp ${BUILD_DIR_TIFF}/build/libtiff/*.h .

WORKDIR /opt/app
COPY ./app .

#-------------------------------------------------------------------------------
# Build openjpeg libraries
#-------------------------------------------------------------------------------
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y -f --no-install-recommends \
    tree && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Source https://github.com/uclouvain/openjpeg
ARG JPEG_VERSION=2.2.0
ARG JPEG_DIR=${BUILD_DIR}/jpeg
ARG JPEG_SRC_DIR=${JPEG_DIR}/openjpeg-${JPEG_VERSION}
ARG JPEG_BUILD_DIR=${JPEG_SRC_DIR}/build

WORKDIR ${JPEG_DIR}
RUN curl -fsSL https://github.com/uclouvain/openjpeg/archive/refs/tags/v${JPEG_VERSION}.tar.gz|tar -xz

#WORKDIR ${JPEG_SRC_DIR}
#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./configure --host=${ARCH} --prefix=${SDK_LIB_PATH_BASE} cc=${CC%-gcc*}-gcc
#RUN make -j "$(nproc)" && \
#    make install
RUN ls ${JPEG_DIR}
RUN mkdir ${JPEG_BUILD_DIR}

WORKDIR ${JPEG_BUILD_DIR}

RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc \
        cmake -G"Unix Makefiles" .. \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE && \
        make -j && make install; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

RUN tree ${JPEG_BUILD_DIR}/

WORKDIR /opt/app/lib
RUN cp -P ${JPEG_BUILD_DIR}/libopenjp2.pc .
RUN cp ${JPEG_BUILD_DIR}/bin/*.so* .
#/opt/build/jpeg/openjpeg-2.2.0/src/lib/
WORKDIR /opt/app/include
RUN cp -r ${JPEG_SRC_DIR}/src/lib/* .
RUN cp -r ${JPEG_SRC_DIR}/src/lib/* ${SDK_LIB_PATH_BASE}/include
#RUN ln -s openjp2 openjpeg-2.2
RUN mkdir openjpeg-2.2
RUN cp openjp2/openjpeg.h openjpeg-2.2/
RUN ls ${SDK_LIB_PATH_BASE}/include/openjpeg-2.2
#RUN mkdir ${SDK_LIB_PATH_BASE}/include/openjpeg-2.2
RUN cp ${SDK_LIB_PATH_BASE}/include/openjp2/openjpeg.h ${SDK_LIB_PATH_BASE}/include/openjpeg-2.2
RUN cp -r ${SDK_LIB_PATH_BASE}/include/openjpeg-2.2/openjpeg.h /opt/app/include/openjpeg-2.2/
#RUN find ${JPEG_DIR} -name "*.h"

#RUN tree ${SDK_LIB_PATH_BASE}
#WORKDIR /opt/app
#COPY ./app .

#RUN find /opt/app -name "openjpeg.h"|grep openjpeg-2.2
RUN find ${SDK_LIB_PATH_BASE}/include/openjpeg-2.2 -name "openjpeg.h"|grep openjpeg-2.2
RUN ls /opt/app/include/openjpeg-2.2 -lha
RUN find /opt/app/include/openjpeg-2.2 -name "openjpeg.h"|grep openjpeg-2.2

#-------------------------------------------------------------------------------
# Build Leptonica libraries
#-------------------------------------------------------------------------------

ARG LEPTONICA_VERSION=1.74.0
ARG LEPTONICA_DIR=${BUILD_DIR}/leptonica
ARG LEPTONICA_SRC_DIR=${LEPTONICA_DIR}/leptonica-${LEPTONICA_VERSION}
#ARG LEPTONICA_BUILD_DIR=${LEPTONICA_DIR}/build/

WORKDIR ${LEPTONICA_DIR}
RUN curl -fsSL https://github.com/DanBloomberg/leptonica/archive/${LEPTONICA_VERSION}.tar.gz|tar -xz

WORKDIR ${LEPTONICA_SRC_DIR}
#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./autogen.sh

#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./configure --host=${ARCH}     --disable-programs \
#                                   --without-giflib \
#                                   --without-libwebp \
#                                   --without-zlib \
#                                   --without-libopenjpeg --prefix=${LEPTONICA_BUILD_DIR}
##RUN . /opt/axis/acapsdk/environment-setup* && \
##    ./configure --host=${ARCH} --prefix=${SDK_LIB_PATH_BASE}
#RUN make -j && make install

RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc \
        cmake -G"Unix Makefiles" -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -DBUILD_PROG=OFF \
        -DSW_BUILD=OFF \
        -DBUILD_SHARED_LIBS=ON && \
        cmake --build build --config Release && make -j && make install; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc \
        cmake -G"Unix Makefiles" -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -DBUILD_PROG=OFF \
        -DSW_BUILD=OFF \
        -DBUILD_SHARED_LIBS=ON && \
        cmake --build build --config Release && make -j && make install; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

#RUN . /opt/axis/acapsdk/environment-setup* && \
#    cmake -Bbuild \
#    -DCMAKE_BUILD_TYPE=Release \
#    -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
#    -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
#    -DBUILD_PROG=OFF \
#    -DSW_BUILD=OFF \
#    -DBUILD_SHARED_LIBS=ON
#RUN . /opt/axis/acapsdk/environment-setup* && \
#    cmake --build build  --config Release --target install -j

WORKDIR /opt/app
COPY ./app .
#RUN ls $SDK_LIB_PATH_BASE/lib/pkgconfig -la
#RUN #ls $SDK_LIB_PATH_BASE/lib -la
RUN mkdir ./pkgconfig
#RUN cp -r ${SDK_LIB_PATH_BASE}/lib/pkgconfig/lept_Release.pc ${SDK_LIB_PATH_BASE}/lib/pkgconfig/lept.pc
RUN cp -r ${SDK_LIB_PATH_BASE}/lib/pkgconfig/* ./pkgconfig
RUN #ls -lha ./pkgconfig
RUN #find / -name *libleptonica.so*
RUN cp -r ${SDK_LIB_PATH_BASE}/lib/libleptonica.so* ./lib/
RUN ls ${SDK_LIB_PATH_BASE}/include/leptonica/allheaders.h
RUN cp -r ${SDK_LIB_PATH_BASE}/include/leptonica ./include/
RUN cp -r ${SDK_LIB_PATH_BASE}/include/leptonica/*.h ${SDK_LIB_PATH_BASE}/include
RUN cp -r ${SDK_LIB_PATH_BASE}/include/leptonica/allheaders.h ./include/

#-------------------------------------------------------------------------------
# Build Tesseract libraries
#-------------------------------------------------------------------------------

ARG TESSERACT_VERSION=3.05.02
ARG TESSERACT_DIR=${BUILD_DIR}/tesseract
ARG TESSERACT_SRC_DIR=${TESSERACT_DIR}/tesseract-${TESSERACT_VERSION}
ARG TESSERACT_BUILD_DIR=${TESSERACT_DIR}/build

WORKDIR ${TESSERACT_DIR}
RUN curl -fsSL https://github.com/tesseract-ocr/tesseract/archive/${TESSERACT_VERSION}.tar.gz|tar -xz

#WORKDIR ${TESSERACT_BUILD_DIR}
#ENV COMMON_CMAKE_FLAGS="-S $TESSERACT_SRC_DIR \
#        -B $TESSERACT_BUILD_DIR \
#        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
#        -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN} \
#        -D CMAKE_BUILD_TYPE=RELEASE \
#        -DBUILD_PROG=OFF -DSW_BUILD=OFF -DBUILD_SHARED_LIBS=ON"


#export LEPTONICA_LIBS="-L$ROOT/output/$OUTARCH/lib -llept"
#export LEPTONICA_CFLAGS="-I$ROOT/output/$OUTARCH/include/leptonica"
#export PKG_CONFIG_PATH="$ROOT/output/$OUTARCH/lib/pkgconfig"

WORKDIR ${TESSERACT_BUILD_DIR}
#RUN . /opt/axis/acapsdk/environment-setup* && \
#    cmake -S${TESSERACT_SRC_DIR}  \
#    -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
#    -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
#    -D CMAKE_BUILD_TYPE=Release \
#    -D BUILD_TRAINING_TOOLS=OFF \
#    -D SW_BUILD=OFF \
#    -D OPENMP_BUILD=OFF \
#    -D BUILD_SHARED_LIBS=ON

RUN if [ "$ARCH" = armv7hf ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        gCFLAGS=' -O2 -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a9 -fomit-frame-pointer' \
        CC=arm-linux-gnueabihf-gcc \
        cmake -G"Unix Makefiles" -S ${TESSERACT_SRC_DIR} \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
        -D Leptonica_DIR=${LEPTONICA_SRC_DIR}/cmake \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TRAINING_TOOLS=OFF \
        -D SW_BUILD=OFF \
        -D OPENMP_BUILD=OFF \
        -D BUILD_SHARED_LIBS=ON && \
        make -j && make install; \
    elif [ "$ARCH" = aarch64 ]; then \
        # Source SDK environment to get cross compilation tools
        . /opt/axis/acapsdk/environment-setup* && \
        CC=/usr/bin/aarch64-linux-gnu-gcc \
        cmake -G"Unix Makefiles" -S ${TESSERACT_SRC_DIR} \
        -D CMAKE_PREFIX_PATH=$SDK_LIB_PATH_BASE \
        -D CMAKE_INSTALL_PREFIX=$SDK_LIB_PATH_BASE \
        -D Leptonica_DIR=${LEPTONICA_SRC_DIR}/cmake \
        -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_TRAINING_TOOLS=OFF \
        -D SW_BUILD=OFF \
        -D OPENMP_BUILD=OFF && \
        make -j && make install; \
    else \
        printf "Error: '%s' is not a valid value for the ARCH variable\n", "$ARCH"; \
        exit 1; \
    fi

#RUN . /opt/axis/acapsdk/environment-setup* && \
#    ./configure --host=${ARCH} cc=${CC%-gcc*}-gcc \
#                --disable-doc \
#                --without-archive \
#                --disable-openmp \
#                --without-curl \
#                --prefix=${SDK_LIB_PATH_BASE} \
#

#WORKDIR ${TESSERACT_BUILD_DIR}
#RUN ls . && make -j && make install

##-------------------------------------------------------------------------------
## Copy the built library files to application directory
##-------------------------------------------------------------------------------

WORKDIR /opt/app
COPY ./app .
COPY ./eng.traineddata .
RUN cp -P ${TESSERACT_BUILD_DIR}/lib*.so* ./lib/
RUN cp -P ${TESSERACT_BUILD_DIR}/tesseract.pc ./lib/
RUN sed -i 's/tesseract_OUTPUT_NAME-NOTFOUND/tesseract/g' ./lib/tesseract.pc
RUN sed -i 's/tesseract_OUTPUT_NAME-NOTFOUND/tesseract/g' ${TESSERACT_BUILD_DIR}/tesseract.pc
RUN cat ./lib/tesseract.pc
#RUN cp -P ${TESSERACT_BUILD_DIR}/tesseract.pc.in ./lib/
#RUN cp -P ${TESSERACT_BUILD_DIR}/tesseract_Release.pc ./lib/
#RUN tree ${TESSERACT_BUILD_DIR}
RUN tree ${LEPTONICA_SRC_DIR}/cmake
#RUN cp -r ${TESSERACT_BUILD_DIR}/include/* ./include/
ENV TESSDATA_PREFIX=/opt/app


#-------------------------------------------------------------------------------
# Finally build the ACAP application
#-------------------------------------------------------------------------------
WORKDIR /opt/app
COPY ./app .
RUN . /opt/axis/acapsdk/environment-setup* && acap-build . -a 'eng.traineddata'
