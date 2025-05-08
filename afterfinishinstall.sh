#!/bin/bash

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
  -m 1024 \
  -smp 1 \
  -cpu host \
  -enable-kvm \
  -hda /root/lubuntu.qcow2 \
  -boot c \
  -vnc :1,password \
  -k en-us \
  -netdev user,id=mynet,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=mynet \
  -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

  {
  echo "change vnc password"
  echo "pas123"
} | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock

#kompres&backup
qemu-img convert -c -O qcow2 /root/lubuntu.qcow2 /root/lubuntu-compress.qcow2
rsync -avz -e ssh /lokal/path/file.txt user@ip_tujuan:/path/tujuan/

#restore
sudo apt install qemu-utils -y
qemu-img convert -O raw /root/lubuntu-compress.qcow2 - | dd of=/dev/vda bs=4M status=progress
sync
