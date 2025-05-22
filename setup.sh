#!/bin/bash

CONFIG_FILE="setqemu.conf"

# Load konfigurasi jika ada
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  # Nilai default jika config tidak ditemukan
  VNC_PASSWORD="pass123"
  SETRAM=1024
  SETCPU=1
  SETHDD="$HOME/ubuntu.qcow2"
  SETISO="https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
fi

pause() {
  read -p "Press Enter to return to the menu..."
}

save_config() {
  cat <<EOF > "$CONFIG_FILE"
VNC_PASSWORD=$VNC_PASSWORD
SETRAM=$SETRAM
SETCPU=$SETCPU
SETHDD="$SETHDD"
SETISO="$SETISO"
EOF
}

display_info() {
  echo "Konfigurasi saat ini:"
  echo "RAM         : $SETRAM MB"
  echo "CPU Core    : $SETCPU"
  echo "Disk File   : $SETHDD"
  echo "ISO Install : $SETISO"
  echo "VNC Password: $VNC_PASSWORD"
}

while true; do
  clear
  display_info
  echo "========================================"
  echo "           QEMU Menu"
  echo "========================================"
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
      read -e -i "$VNC_PASSWORD" -p "Set VNC password: " VNC_PASSWORD
      sudo mkdir -p /root/.vnc
      sudo x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
      save_config
      pause
      ;;
    2)
      read -e -i "$SETRAM" -p "Set RAM (MB): " SETRAM
      read -e -i "$SETCPU" -p "Set CPU cores: " SETCPU
      read -e -i "$SETHDD" -p "Set QCOW2 disk file: " SETHDD
      read -e -i "$SETISO" -p "Set ISO installation URL: " SETISO
      save_config
      if [ ! -f "$SETISO" ]; then
        echo "Mengunduh ISO..."
        wget -O mini.iso "$SETISO"
        SETISO="./mini.iso"
        save_config
      fi

      qemu-system-x86_64 \
         -m $SETRAM \
         -smp $SETCPU \
         -cpu host \
         -enable-kvm \
         -hda "$SETHDD" \
         -cdrom "$SETISO" \
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
      echo "QEMU running. VNC on localhost:5901 with password: $VNC_PASSWORD"
      pause
      ;;
    3)
      pkill qemu-system-x86_64
      QEMU_PIDS=$(ps aux | grep '[q]emu-system' | awk '{print $2}')
      if [ -z "$QEMU_PIDS" ]; then
        echo "Tidak ada proses QEMU yang ditemukan."
      else
        kill -9 $QEMU_PIDS
        echo "Proses QEMU dengan PID $QEMU_PIDS berhasil dimatikan."
      fi

      qemu-system-x86_64 \
        -m $SETRAM \
        -smp $SETCPU \
        -cpu host \
        -enable-kvm \
        -hda "$SETHDD" \
        -boot c \
        -vnc :1,password \
        -k en-us \
        -netdev user,id=mynet,hostfwd=tcp::2222-:22,hostfwd=tcp::5911-:5900 \
        -device e1000,netdev=mynet \
        -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

      sleep 5
      {
        echo "change vnc password"
        echo "$VNC_PASSWORD"
      } | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
      pause
      ;;
    4)
      read -e -i 18 -p "Create disk size (GB): " SIZEHDD
      read -e -i "$SETHDD" -p "Save disk as file: " SETHDD
      qemu-img create -f qcow2 "$SETHDD" "${SIZEHDD}G"
      save_config
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
