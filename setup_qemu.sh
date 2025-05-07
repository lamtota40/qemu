#!/bin/bash

# Path untuk file ISO Lubuntu dan image disk
LUBUNTU_ISO_URL="https://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-alternate-amd64.iso"
LUBUNTU_ISO="/tmp/lubuntu-18.04-alternate-amd64.iso"
LUBUNTU_IMG="/root/lubuntu.img"

# Ukuran disk image dalam GB
DISK_SIZE=19

# Install QEMU dan dependensi yang diperlukan
echo "Memasang QEMU dan dependensi..."
sudo apt update
sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc

# Mengunduh ISO Lubuntu
echo "Mengunduh ISO Lubuntu 18.04..."
wget -O "$LUBUNTU_ISO" "$LUBUNTU_ISO_URL"

# Membuat image disk untuk Lubuntu
echo "Membuat image disk untuk Lubuntu dengan ukuran $DISK_SIZE GB..."
qemu-img create -f raw "$LUBUNTU_IMG" "${DISK_SIZE}G"

mkdir -p /root/.vnc
x11vnc -storepasswd $VNC_PASSWORD /root/.vnc/passwd




