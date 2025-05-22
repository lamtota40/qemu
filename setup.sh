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
    apt update
    apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc socat
    read -e -i "pass123" -p "settup your password vnc: " VNC_PASSWORD
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
    pause
    ;;
  2)
  read -e -i 1024 -p "sett ram (Mb) : " setram
  read -e -i 1 -p "sett core cpu : " setcpu
  read -e -i "$Home/ubuntu.qcow2" -p "sett location & file cow2 : " sethdd
  read -e -i "$Home/lubuntu-18.04-alternate-amd64.iso" -p "Sett iso instalation OS : " setiso
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
echo "[6/6] Mengatur password VNC via monitor socket..."
{
  echo "change vnc password"
  echo "$VNC_PASSWORD"
} | socat - UNIX-CONNECT:$MONITOR_SOCKET
    pause
    ;;
  3)
    clear
    
    pause
    ;;
  4)
    clear
    qemu-img create -f qcow2 "$LUBUNTU_IMG" $DISK_SIZE
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
