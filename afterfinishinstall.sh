qemu-system-x86_64 \
  -m 1024 \
  -smp 1 \
  -cpu host \
  -enable-kvm \
  -hda /root/lubuntu.img \
  -boot c \
  -vnc :1,password \
  -k en-us \
  -net nic \
  -net user \
  -monitor unix:/tmp/qemu-monitor.sock,server,nowait &

{
  echo "change vnc password"
  echo "pas123"
} | socat - UNIX-CONNECT:/tmp/qemu-monitor.sock
