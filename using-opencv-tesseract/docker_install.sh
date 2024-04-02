#!/usr/bin/env bash
host=""
password=""
if [[ -z $host ]]; then
    read -p "Enter your ip/host : " host
fi

if [[ -z $password ]]; then
    read -s -p "Enter the password of root user : " password
    echo
fi

docker run -it exemple_using_opencv_tesseract_1_0 /opt/axis/acapsdk/sysroots/x86_64-pokysdk-linux/usr/bin/eap-install.sh $host $password install
docker run -it exemple_using_opencv_tesseract_1_0 /opt/axis/acapsdk/sysroots/x86_64-pokysdk-linux/usr/bin/eap-install.sh $host $password stop
docker run -it exemple_using_opencv_tesseract_1_0 /opt/axis/acapsdk/sysroots/x86_64-pokysdk-linux/usr/bin/eap-install.sh $host $password start
