#!/bin/bash

CONFIG_FILE="setqemu.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

pause() {
  read -p "Press Enter to return to the menu..."
}

save_config() {
cat > "$CONFIG_FILE" <<EOF
VNC_PASSWORD="$VNC_PASSWORD"
setcpu="$setcpu"
setram="$setram"
sethdd="$sethdd"
setiso="$setiso"
external_disk="$external_disk"
EOF
}

display_info() {
  echo "========================================"
  echo "         QEMU MANAGER"
  echo "========================================"
  if command -v qemu-system-x86_64 &> /dev/null; then
    echo "Status QEMU     : Installed"
  else
    echo "Status QEMU     : Not Installed"
  fi

  CPU_CORES=$(nproc)
  CPU_SPEED=$(lscpu | grep "MHz" | awk '{print int($3)}')
  echo "Core CPU        : ${CPU_CORES} core | ${CPU_SPEED} MHz"

  if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) -gt 0 ]]; then
    echo "Type            : KVM | Virtualization Enabled"
  else
    echo "Type            : Unknown | Virtualization Not Supported"
  fi

  ram_total=$(free -m | awk '/Mem:/ {print $2}')
  ram_used=$(free -m | awk '/Mem:/ {print $3}')
  ram_free=$(free -m | awk '/Mem:/ {print $4}')
  ram_percent=$(($ram_used * 100 / $ram_total))
  echo "RAM             : Usage: ${ram_used}MB (${ram_percent}%) | Free: ${ram_free}MB | Total: ${ram_total}MB"

  swap_total=$(free -m | awk '/Swap:/ {print $2}')
  swap_used=$(free -m | awk '/Swap:/ {print $3}')
  swap_free=$(free -m | awk '/Swap:/ {print $4}')
  if [[ "$swap_total" -gt 0 ]]; then
    swap_percent=$(($swap_used * 100 / $swap_total))
  else
    swap_percent=0
  fi
  echo "Swap RAM        : Usage: ${swap_used}MB (${swap_percent}%) | Free: ${swap_free}MB | Total: ${swap_total}MB"

  hdd_usage=$(df -h / | awk 'NR==2 {print $3}')
  hdd_free=$(df -h / | awk 'NR==2 {print $4}')
  hdd_total=$(df -h / | awk 'NR==2 {print $2}')
  hdd_percent=$(df -h / | awk 'NR==2 {print $5}')
  echo "HDD             : Usage: ${hdd_usage} (${hdd_percent}) | Free: ${hdd_free} | Total: ${hdd_total}"
  echo "========================================"
}

while true; do
  clear
  display_info
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
      clear
      echo "Installasi QEMU telah berhasil."
      read -e -i "pass123" -p "Set VNC password: " VNC_PASSWORD
      sudo mkdir -p /root/.vnc
      sudo x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
      save_config
      pause
      ;;
    2)
      LINKISO="https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
      read -e -i 1024 -p "Set RAM (MB): " setram
      read -e -i 1 -p "Set CPU core: " setcpu
      read -e -i "$HOME/ubuntu.qcow2" -p "Set main disk path: " sethdd
      read -e -i "$LINKISO" -p "Set ISO URL or path: " setiso
      if [ ! -f "$setiso" ]; then
        echo "Downloading ISO..."
        wget -O mini.iso "$LINKISO"
        setiso="mini.iso"
      fi
      save_config
      qemu-system-x86_64 \
        -m "$setram" \
        -smp "$setcpu" \
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
      echo "QEMU is running with VNC on localhost:5901"
      pause
      ;;
    3)
      pkill qemu-system-x86_64
      external_disk="$HOME/external_hdd.qcow2"
      [ ! -f "$external_disk" ] && qemu-img create -f qcow2 "$external_disk" 10G
      save_config
      qemu-system-x86_64 \
        -m "$setram" \
        -smp "$setcpu" \
        -cpu host \
        -enable-kvm \
        -hda "$sethdd" \
        -boot c \
        -vnc :1,password \
        -k en-us \
        -netdev user,id=mynet,hostfwd=tcp::2222-:22,hostfwd=tcp::5911-:5900 \
        -device e1000,netdev=mynet \
        -drive file="$external_disk",format=qcow2,if=virtio \
        -monitor unix:/tmp/qemu-monitor.sock,server,nowait &
      sleep 3
      {
        echo "change vnc password"
        echo "$VNC_PASSWORD"
      } | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
      echo "QEMU with external disk is running..."
      pause
      ;;
    4)
      read -e -i "$HOME/ubuntu.qcow2" -p "Enter disk path: " fileqcow
      read -e -i 18 -p "Set disk size (GB): " setsizehdd
      qemu-img create -f qcow2 "$fileqcow" "${setsizehdd}G"
      echo "Disk created: $fileqcow"
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
