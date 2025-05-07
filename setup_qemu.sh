#!/bin/bash

# Path untuk file ISO Lubuntu dan image disk
LUBUNTU_ISO_URL="https://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-alternate-amd64.iso"
LUBUNTU_ISO="/tmp/lubuntu-18.04-alternate-amd64.iso"
#LUBUNTU_IMG="/home/$USER/lubuntu.img"
LUBUNTU_IMG="/root/lubuntu.img"

# Ukuran disk image dalam GB
DISK_SIZE=20

# Install QEMU dan dependensi yang diperlukan
echo "Memasang QEMU dan dependensi..."
sudo apt update
sudo apt install -y qemu qemu-kvm libvirt-bin bridge-utils virt-manager wget

# Mengunduh ISO Lubuntu
echo "Mengunduh ISO Lubuntu 18.04..."
wget -O "$LUBUNTU_ISO" "$LUBUNTU_ISO_URL"

# Membuat image disk untuk Lubuntu
echo "Membuat image disk untuk Lubuntu dengan ukuran $DISK_SIZE GB..."
qemu-img create -f raw "$LUBUNTU_IMG" "${DISK_SIZE}G"

# Menjalankan instalasi Lubuntu menggunakan QEMU
echo "Menjalankan instalasi Lubuntu 18.04..."
qemu-system-x86_64 \
  -m 1G \
  -cpu host \
  -smp 1 \
  -hda "$LUBUNTU_IMG" \
  -cdrom "$LUBUNTU_ISO" \
  -boot d \
  -enable-kvm \
  -nographic

# Setelah instalasi selesai, shutdown VM
echo "Instalasi selesai. Mematikan virtual machine..."
sudo shutdown -h now

echo "Selesai! Lubuntu 18.04 telah terinstal di $LUBUNTU_IMG"
