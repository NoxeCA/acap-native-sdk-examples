#!/usr/bin/env bash
docker build --progress=plain --tag exemple_using_opencv_tesseract_1_0 .
#docker build --progress=plain --build-arg ARCH=aarch64 --tag exemple_using_opencv_tesseract_1_0 .
#docker build --progress=plain --no-cache --tag exemple_using_opencv_tesseract_1_0 .
rm -rf ./build
docker cp "$(docker create exemple_using_opencv_tesseract_1_0):/opt/app" ./build
