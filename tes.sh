#!/bin/bash
# qemu-rev4.sh

CONFIG_FILE="./setqemu.conf"
source "$CONFIG_FILE" 2>/dev/null || touch "$CONFIG_FILE"

# Fungsi pause
pause() {
  read -p "Press Enter to return to the menu..."
}

# Fungsi tampilkan info sistem
display_info() {
  echo "========================================"
  echo "           QEMU MANAGER"
  echo "========================================"

  if command -v qemu-system-x86_64 &> /dev/null; then
    echo "QEMU Status     : Installed"
  else
    echo "QEMU Status     : Not Installed"
  fi

  cpu_core=$(nproc)
  cpu_speed=$(awk -F: '/MHz/ {print int($2); exit}' /proc/cpuinfo)
  echo "CPU Core/Speed  : $cpu_core core | ${cpu_speed}MHz"

  virt_type=$(systemd-detect-virt)
  if [[ "$virt_type" == "none" ]]; then
    virt_type="Bare Metal"
  fi

if egrep -q '(vmx|svm)' /proc/cpuinfo; then
    if lsmod | grep -q 'kvm_intel' || lsmod | grep -q 'kvm_amd'; then
        virt_support="support Virtualization(enable)"
    else
        virt_support="support Virtualization(disable)"
    fi
else
    virt_support="Not support Virtualization(disable)"
fi

  echo "Type            : $virt_type" | $virt_support

  read mem_total mem_used <<< $(free -m | awk '/^Mem:/ {print $2, $3}')
  mem_free=$((mem_total - mem_used))
  mem_percent=$((mem_used * 100 / mem_total))
  echo "RAM             : Usage: ${mem_used}MB (${mem_percent}%) | Free: ${mem_free}MB | Total: ${mem_total}MB"

  read swap_total swap_used <<< $(free -m | awk '/^Swap:/ {print $2, $3}')
  swap_free=$((swap_total - swap_used))
  if [[ "$swap_total" -gt 0 ]]; then
    swap_percent=$((swap_used * 100 / swap_total))
  else
    swap_percent=0
  fi
  echo "Swap RAM        : Usage: ${swap_used}MB (${swap_percent}%) | Free: ${swap_free}MB | Total: ${swap_total}MB"

  hdd_usage=$(df -h --total | awk '/total/ {print $3}')
  hdd_total=$(df -h --total | awk '/total/ {print $2}')
  hdd_free=$(df -h --total | awk '/total/ {print $4}')
  hdd_percent=$(df -h --total | awk '/total/ {print $5}')
  echo "HDD             : Usage: $hdd_usage ($hdd_percent) | Free: $hdd_free | Total: $hdd_total"

  echo "========================================"
}

clear
display_info
echo ""
echo "1. Install QEMU"
echo "2. Install OS"
echo "3. Run OS"
echo "4. Create Disk"
echo "0. Exit"
echo "========================================"
read -p "Enter your choice number: " choice

case $choice in
  1)
    sudo apt update
    sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc socat
    clear
    echo "Instalasi Qemu telah selesai.."
    read -e -i "pass123" -p "Set your VNC password: " vncpassword
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$vncpassword" /root/.vnc/passwd
    echo "vncpassword=$vncpassword" > "$CONFIG_FILE"
    pause
    ;;
  2)
    if ! command -v qemu-system-x86_64 &>/dev/null; then
      echo "Silahkan pilih no 1 terlebih dahulu karena QEMU belum terinstal."
      pause
      exit
    fi
    LINKISO="https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
    read -e -i 1024 -p "Set RAM (MB): " setcpu_ram
    read -e -i 1 -p "Set core CPU: " setcpu_core
    read -e -i "$HOME/ubuntu.qcow2" -p "Set disk image path: " disk_image
    read -e -i "$LINKISO" -p "Set ISO URL: " iso_url

    echo "setcpu_ram=$setcpu_ram" >> "$CONFIG_FILE"
    echo "setcpu_core=$setcpu_core" >> "$CONFIG_FILE"
    echo "disk_image=$disk_image" >> "$CONFIG_FILE"
    echo "iso_url=$iso_url" >> "$CONFIG_FILE"

    if [ ! -f mini.iso ]; then
      wget "$LINKISO" -O mini.iso
    fi

    qemu-system-x86_64 \
      -m "$setcpu_ram" \
      -smp "$setcpu_core" \
      -cpu host \
      -enable-kvm \
      -hda "$disk_image" \
      -cdrom mini.iso \
      -boot d \
      -vnc :1,password \
      -k en-us \
      -net nic \
      -net user \
      -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

    sleep 3
    {
      echo "change vnc password"
      echo "$vncpassword"
    } | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock

    echo "QEMU is running. Access via VNC on localhost:5901"
    pause
    ;;
  3)
    if ! command -v qemu-system-x86_64 &>/dev/null; then
      echo "Silahkan pilih no 1 terlebih dahulu karena QEMU belum terinstal."
      pause
      exit
    fi

    source "$CONFIG_FILE"
    pkill qemu-system-x86_64

    qemu-system-x86_64 \
      -m "$setcpu_ram" \
      -smp "$setcpu_core" \
      -cpu host \
      -enable-kvm \
      -hda "$disk_image" \
      -boot c \
      -vnc :1,password \
      -k en-us \
      -drive file=external_hdd.qcow2,format=qcow2,if=virtio
      -netdev user,id=mynet,hostfwd=tcp::2222-:22,hostfwd=tcp::5911-:5900 \
      -device e1000,netdev=mynet \
      -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

    sleep 3
    {
      echo "change vnc password"
      echo "$vncpassword"
    } | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock

    echo "QEMU running. VNC available on localhost:5901"
    pause
    ;;
  4)
    read -e -i 18 -p "Set disk size (GB): " disk_size
    read -e -i "$HOME/ubuntu.qcow2" -p "Set output file (.qcow2): " fileqcow
    qemu-img create -f qcow2 "$fileqcow" "${disk_size}G"
    echo "Created disk: $fileqcow with size ${disk_size}G"
    pause
    ;;
  0)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "Invalid choice."
    pause
    ;;
esac
