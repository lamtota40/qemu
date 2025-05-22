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
   read -p "settup your password vnc: " VNC_PASSWORD
   
   mkdir -p /root/.vnc
   x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
    pause
    ;;
  2)
    
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
