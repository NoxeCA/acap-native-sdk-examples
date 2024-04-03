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

# Bug replace lib
# libstdc++.so.6.0.30
#scp lib/*.so* root@${host}:/mnt/flash/usr/local/packages/opencv_tesseract_app/lib/
sshpass -p $password scp lib/*.so* root@${host}:/mnt/flash/usr/local/packages/opencv_tesseract_app/lib/

docker run -it exemple_using_opencv_tesseract_1_0 /opt/axis/acapsdk/sysroots/x86_64-pokysdk-linux/usr/bin/eap-install.sh $host $password stop
docker run -it exemple_using_opencv_tesseract_1_0 /opt/axis/acapsdk/sysroots/x86_64-pokysdk-linux/usr/bin/eap-install.sh $host $password start
