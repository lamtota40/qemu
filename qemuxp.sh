#!/bin/bash
# qemu-rev8.sh

CONFIG_FILE="./setqemu.conf"
source "$CONFIG_FILE" 2>/dev/null || touch "$CONFIG_FILE"

pause() {
  read -p "Press Enter to return to the menu..."
}

kill_qemu(){
pkill qemu-system-x86_64
QEMU_PIDS=$(ps aux | grep '[q]emu-system' | awk '{print $2}')
if [ -z "$QEMU_PIDS" ]; then
  echo "Tidak ada proses QEMU yang ditemukan."
else
  kill -9 $QEMU_PIDS
  echo "Ditemukan dengam PID: $QEMU_PIDS dan berhasil kill."
fi
}

# Fungsi tampilkan info sistem
display_info() {
  echo "=================================================="
  echo "           QEMU MANAGER"
  echo "=================================================="

QEMU_PIDS=$(ps aux | grep '[q]emu-system' | awk '{print $2}')
if [ -z "$QEMU_PIDS" ]; then
  stat="Not Running"
else
  stat="Running PID: $QEMU_PIDS"
fi

  if command -v qemu-system-x86_64 &> /dev/null; then
    echo "QEMU Status     : Installed | $stat"
  else
    echo "QEMU Status     : Not Installed | $stat"
  fi

  cpu_core=$(nproc)
  cpu_speed=$(awk -F: '/MHz/ {print int($2); exit}' /proc/cpuinfo)
  echo "CPU Core/Speed  : $cpu_core core | ${cpu_speed}MHz"

virt_type=$(systemd-detect-virt 2>/dev/null)
  if [ "$virt_type" == "none" ]; then
    virt_type="BareMetal"
  elif [ -z "$virt_type" ]; then
    virt_type="Unknown"
  fi

if egrep -q '(vmx|svm)' /proc/cpuinfo; then
    if lsmod | grep -q 'kvm_intel' || lsmod | grep -q 'kvm_amd'; then
        virt_support="Support Virtualization(enable)"
    else
        virt_support="Support Virtualization(disable)"
    fi
else
    virt_support="Not Support Virtualization(disable)"
fi

  echo "Type            : $virt_type | $virt_support"

  read mem_total mem_used <<< $(free -m | awk '/^Mem:/ {print $2, $3}')
  mem_free=$((mem_total - mem_used))
  mem_percent=$((mem_used * 100 / mem_total))
  echo "RAM             : Usage: ${mem_used} MB (${mem_percent}%) | Free: ${mem_free} MB | Total: ${mem_total} MB"

  read swap_total swap_used <<< $(free -m | awk '/^Swap:/ {print $2, $3}')
  swap_free=$((swap_total - swap_used))
  if [[ "$swap_total" -gt 0 ]]; then
    swap_percent=$((swap_used * 100 / swap_total))
  else
    swap_percent=0
  fi
  echo "Swap RAM        : Usage: ${swap_used} MB (${swap_percent}%) | Free: ${swap_free} MB | Total: ${swap_total} MB"

  hdd_usage=$(df -h --total | awk '/total/ {print $3}')
  hdd_total=$(df -h --total | awk '/total/ {print $2}')
  hdd_free=$(df -h --total | awk '/total/ {print $4}')
  hdd_percent=$(df -h --total | awk '/total/ {print $5}')
  echo "HDD             : Usage: $hdd_usage ($hdd_percent) | Free: $hdd_free | Total: $hdd_total"

  echo "=================================================="
}
while true; do
clear
display_info
echo ""
echo "1. Install QEMU"
echo "2. Install OS"
echo "3. Run OS"
echo "4. Create Disk"
echo "5. Stop Running"
echo "0. Exit"
echo "=================================================="
read -p "Enter your choice number: " choice

case $choice in
  1)
    sudo apt update
    sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager wget x11vnc socat
    clear
    echo "Instalasi Qemu telah selesai.."
    while true; do
  read -p "Set disk size (GB): " disk_size
if [[ "$disk_size" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  break
else
  echo "Input tidak valid. Hanya angka dan titik sebagai desimal."
fi
done

read -e -i "ubuntu" -p "Set file name: " filename
fileqcow="$HOME/${filename}.qcow2"
    qemu-img create -f qcow2 "$fileqcow" "${disk_size}G"
    echo "Created disk: $fileqcow with size ${disk_size}G"
    echo "disk_image=$fileqcow" >> "$CONFIG_FILE"
    
    read -e -i "pass123" -p "Set your VNC password: " vncpassword
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$vncpassword" /root/.vnc/passwd
    echo "vncpassword=$vncpassword" >> "$CONFIG_FILE"
    pause
    ;;
  2)
    if ! command -v qemu-system-x86_64 &>/dev/null; then
      echo "Silahkan pilih no 1 terlebih dahulu karena QEMU belum terinstal."
      pause
      continue
    fi
    kill_qemu
    source "$CONFIG_FILE"
if [ -z "$vncpassword" ]; then
  read -e -i "pass123" -p "Set your VNC password: " vncpassword
  echo "vncpassword=$vncpassword" >> "$CONFIG_FILE"
fi

    LINKISO="https://archive.org/download/WinXPProSP3x86/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso"
    read -e -i 1024 -p "Set RAM (MB): " setcpu_ram
    read -e -i 1 -p "Set core CPU: " setcpu_core
    read -e -i "$HOME/winxp.qcow2" -p "Set disk image path: " disk_image
    read -e -i "$LINKISO" -p "Set ISO URL: " iso_url
    [ -f winxp.qcow2 ] || qemu-img create -f qcow2 winxp.qcow2 37.2G

    echo "setcpu_ram=$setcpu_ram" >> "$CONFIG_FILE"
    echo "setcpu_core=$setcpu_core" >> "$CONFIG_FILE"
    echo "disk_image=$disk_image" >> "$CONFIG_FILE"
    echo "iso_url=$iso_url" >> "$CONFIG_FILE"

    if [ ! -f winxp.iso ]; then
      wget -q --show-progress "$LINKISO" -O winxp.iso
    fi
    
qemu-system-x86_64 \
    -m "$setcpu_ram" \
    -smp "$setcpu_core" \
    -cpu pentium \
    -enable-kvm \
    -hda "$disk_image" \
    -cdrom grml.iso \
    -boot d \
    -vnc :1,password \
    -vga std \
    -net nic \
    -net user \
    -rtc base=localtime \
    -monitor unix:/tmp/qemu-monitor.sock,server,nowait &
    sleep 5
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
      continue
    fi

    kill_qemu
    source "$CONFIG_FILE"

    if [ -z "$setcpu_ram" ]; then read -e -i 1024 -p "Set RAM (MB): " setcpu_ram; fi
    if [ -z "$setcpu_core" ]; then read -e -i 1 -p "Set core CPU: " setcpu_core; fi
    if [ -z "$disk_image" ]; then read -e -i "$HOME/winxp.qcow2" -p "Set disk image path: " disk_image; fi
    if [ -z "$vncpassword" ]; then read -e -i "pass123" -p "Set VNC password: " vncpassword; fi
    [ -f external_hdd.qcow2 ] || qemu-img create -f qcow2 external_hdd.qcow2 20G

    qemu-system-x86_64 \
      -m "$setcpu_ram" \
      -smp "$setcpu_core" \
      -cpu host \
      -enable-kvm \
      -hda "$disk_image" \
      -boot c \
      -vnc :1,password \
      -k en-us \
      -drive file=external_hdd.qcow2,format=qcow2,if=virtio \
      -netdev user,id=mynet,hostfwd=tcp::2222-:22,hostfwd=tcp::3389-:3389 \
      -device e1000,netdev=mynet \
      -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

    sleep 5
    {
      echo "change vnc password"
      echo "$vncpassword"
    } | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock

    echo "QEMU running. VNC available on localhost:5901"
    pause
    ;;
  4)
  while true; do
    read -e -i 18 -p "Set disk size (GB): " disk_size
    if [[ "$disk_size" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      break
    else
      echo "Input tidak valid. Hanya angka dan titik sebagai desimal."
    fi
  done

  read -e -i "winxp" -p "Set file name: " filename
  fileqcow="$HOME/${filename}.qcow2"
  qemu-img create -f qcow2 "$fileqcow" "${disk_size}G"
  echo "Created disk: $fileqcow with size ${disk_size}G"
  pause
  ;;
  5)
    echo "Stop QEMU:"
    echo "1. Shutdown"
    echo "2. Forced Stop (possible data loss!)"
    read -p "Pilih sub-menu: " stop_choice

    case $stop_choice in
      1)
if [ -S /tmp/qemu-monitor.sock ]; then
  echo "system_powerdown" | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
  sleep 5
  if ps aux | grep -q '[q]emu-system'; then
    echo "QEMU masih berjalan. Silakan pilih submenu 2 (Forced stop) karena QEMU sedang crash."
  else
    echo "QEMU berhasil dihentikan dengan fallback quit."
  fi
else
  echo "Socket /tmp/qemu-monitor.sock tidak ditemukan. QEMU mungkin tidak berjalan."
fi
        pause
        ;;
      2)
        kill_qemu
        pause
        ;;
      *)
        echo "Pilihan tidak valid."
        pause
        ;;
    esac
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
done
