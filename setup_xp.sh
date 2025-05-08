#!/bin/bash

# Konfigurasi
WINXP_ISO_URL="https://archive.org/download/WinXPProSP3x86/WinXPProSP3x86.iso"
WINXP_ISO="/tmp/windows-xp.iso"
WINXP_IMG="/root/windows-xp.qcow2"
DISK_SIZE=10G
VNC_PASSWORD="pas123"
MONITOR_SOCKET="/tmp/qemu-monitor.sock"

# Install QEMU dan dependensi
echo "[1/6] Memasang QEMU dan dependensi..."
apt update
apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc socat

# Download ISO jika belum ada
echo "[2/6] Mengecek ISO Windows XP..."
if [ ! -f "$WINXP_ISO" ]; then
  echo "Mengunduh ISO Windows XP..."
  wget -O "$WINXP_ISO" "$WINXP_ISO_URL"
else
  echo "ISO sudah tersedia di $WINXP_ISO"
fi

# Buat image jika belum ada
echo "[3/6] Mengecek image disk..."
if [ ! -f "$WINXP_IMG" ]; then
  echo "Membuat disk image $DISK_SIZE..."
  qemu-img create -f qcow2 "$WINXP_IMG" $DISK_SIZE
else
  echo "Image sudah ada di $WINXP_IMG"
fi

# Simpan password VNC
echo "[4/6] Menyimpan password VNC..."
mkdir -p /root/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd

# Jalankan QEMU di background
echo "[5/6] Menjalankan QEMU dengan VNC dan monitor socket..."
qemu-system-x86_64 \
  -m 512 \
  -smp 1 \
  -cpu pentium \
  -hda "$WINXP_IMG" \
  -cdrom "$WINXP_ISO" \
  -boot d \
  -vnc :1,password \
  -k en-us \
  -net nic \
  -net user \
  -monitor unix:$MONITOR_SOCKET,server,nowait &

sleep 5

# Set password VNC melalui monitor QEMU
echo "[6/6] Mengatur password VNC via monitor socket..."
{
  echo "change vnc password"
  echo "$VNC_PASSWORD"
} | socat - UNIX-CONNECT:$MONITOR_SOCKET

echo "Selesai. Windows XP berjalan dengan VNC di localhost:5901"
echo "Gunakan VNC Viewer dan login dengan password: $VNC_PASSWORD"
