#!/bin/bash

# Pause function
pause() {
  read -p "Press Enter to return to the menu..."
}

display_info() {
}

clear
display_info
echo "========================================"
echo "           QEMU Menu"
echo "========================================"
echo "QEMU STATUS : $swap_status"
echo ""
echo "1. Install QEMU"
echo "2. Install OS"
echo "3. Running OS"
echo "4. Create disk"
echo "0. Exit Program"
echo "========================================"
read -p "Enter your choice number: " choice

case $choice in
  1)
    sudo apt update
    sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc socat
    read -e -i "pass123" -p "settup your password vnc: " VNC_PASSWORD
    sudo mkdir -p /root/.vnc
    sudo x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
    pause
    ;;
  2)
  LINKISO="https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
  read -e -i 1024 -p "sett ram (Mb) : " setram
  read -e -i 1 -p "sett core cpu : " setcpu
  read -e -i "$Home/ubuntu.qcow2" -p "sett location & file cow2 : " sethdd
  read -e -i "$LINKISO" -p "Sett link iso instalation OS : " setiso
  if [ ! -f "$Home/mini.iso" ]; then
  echo "Mengunduh ISO Lubuntu..."
  sudo wget https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso
  fi
    qemu-system-x86_64 \
       -m $setram \
       -smp $setcpu \
       -cpu host \
       -enable-kvm \
       -hda "$sethdd" \
       -cdrom "$setiso" \
       -boot d \
       -vnc :1,password \
       -k en-us \
       -net nic \
       -net user \
       -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

       sleep 3
{
  echo "change vnc password"
  echo "$VNC_PASSWORD"
} | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
echo "Selesai. QEMU berjalan dengan VNC di localhost:5901"
echo "Gunakan VNC Viewer dan login dengan password: $VNC_PASSWORD"
    pause
    ;;
  3)
  pkill qemu-system-x86_64
# Cari PID QEMU yang sedang berjalan
QEMU_PIDS=$(ps aux | grep '[q]emu-system' | awk '{print $2}')
if [ -z "$QEMU_PIDS" ]; then
  echo "Tidak ada proses QEMU yang ditemukan."
else
  kill -9 $QEMU_PIDS
  echo "Ditemukan dengam PID: $QEMU_PIDS dan berhasil kill."
fi

qemu-system-x86_64 \
  -m $setram \
  -smp $setcpu \
  -cpu host \
  -enable-kvm \
  -hda $sethdd \
  -boot c \
  -vnc :1,password \
  -k en-us \
  -netdev user,id=mynet,hostfwd=tcp::2222-:22,hostfwd=tcp::5911-:5900 \
  -device e1000,netdev=mynet \
  -monitor unix:/tmp/qemu-monitor.sock,server,nowait &
sleep 5
{
  echo "change vnc password"
  echo "pas123"
} | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
    clear
    
    pause
    ;;
  4)
    clear
    read -e -i 18 -p "Create disk : " setsizehdd
    qemu-img create -f qcow2 "$fileqcow" "$setsizehdd"G
    pause
    ;;
  0)
    echo "Exiting program."
    exit 0
    ;;
  *)
    echo "Unknown choice."
    pause
    ;;
esac
done
