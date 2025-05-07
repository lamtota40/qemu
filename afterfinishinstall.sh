pkill qemu-system-x86_64
ps aux | grep qemu
kill -9 7195

qemu-img create -f qcow2 /root/lubuntu.qcow2 18G

qemu-system-x86_64 \
  -m 1024 \
  -smp 1 \
  -cpu host \
  -enable-kvm \
  -hda /root/lubuntu.img \
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

#restore
qemu-img convert -O raw /root/compress.qcow2 - | dd of=/dev/vda bs=4M status=progress
sync
