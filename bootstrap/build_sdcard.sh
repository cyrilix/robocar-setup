#!/usr/bin/env bash
set -e

# Uncomment and fix variables before run script
SD_CARD_DEVICE="/dev/sda"
SD_CARD_BOOT_PARTITION=${SD_CARD_DEVICE}1
SD_CARD_ROOT_PARTITION=${SD_CARD_DEVICE}2

HOSTNAME_CAR="satanas"

WIFI_SECRET_FILE=".secret"

# For debug
ADD_TTL_SUPPORT_FOR_DEBUG=1

IMAGE_BASE=https://downloads.raspberrypi.org/raspios_lite_arm64_latest

########### End Configuration ############
mkdir -p build

if [ ! -f build/raspbian.zip ]
then
    wget -O build/raspbian.zip ${IMAGE_BASE}
    cd build
    unzip raspbian.zip
    cd ..
fi

raspbian_image=`ls build/*.img`

echo "Copy image ${raspbian_image} to sdcard"
sudo dd if=${raspbian_image} of=${SD_CARD_DEVICE} bs=4M conv=fsync status=progress

echo "Force disk sync"
sync


echo "Mount boot sdcard"
mkdir -p build/mnt
sudo mount ${SD_CARD_BOOT_PARTITION} ./build/mnt

echo "Force ssh to start at first boot"
sudo touch build/mnt/ssh

if [  "${ADD_TTL_SUPPORT_FOR_DEBUG}" == "1" ]
then
    echo "# Disable bluetooth in order to enable serial TTL" | sudo tee -a build/mnt/config.txt > /dev/null
    echo "dtoverlay=pi3-disable-bt" | sudo tee -a build/mnt/config.txt > /dev/null
fi

echo "Copy wifi configuration"
source ${WIFI_SECRET_FILE}
eval "echo \"$(cat wpa_supplicant.conf)\"" | sudo tee build/mnt/wpa_supplicant.conf > /dev/null
sudo chmod 600 build/mnt/wpa_supplicant.conf

echo "Umount boot partition"
sudo umount build/mnt


echo "Mount root sdcard"
sudo mount ${SD_CARD_ROOT_PARTITION} ./build/mnt

echo "Set hostname"
echo ${HOSTNAME_CAR} | sudo tee build/mnt/etc/hostname > /dev/null
echo sudo sed -i "s/raspberrypi/$HOSTNAME_CAR/g" build/mnt/etc/hosts

echo "Disable default password for 'pi' use"
sudo sed -i -E "s/(pi:)[^:]*(:.*)/\1*\2/" build/mnt/etc/shadow*

echo "Copy authorized keys"
sudo mkdir -p build/mnt/home/pi/.ssh/
sudo cp ../ansible/roles/base/files/authorized_keys build/mnt/home/pi/.ssh/
sudo chmod 600 build/mnt/home/pi/.ssh/authorized_keys
sudo chown -R 1000:1000 build/mnt/home/pi



echo "Umount sdcard"
sudo umount ./build/mnt

echo "Force disk sync"
sync

echo "Bootstrap finished, plug sdcard on raspberrypi and connect with command:"
echo "        ssh pi@${HOSTNAME_CAR}.local"

