pkill qemu-system-x86_64
ps aux | grep qemu
kill -9 7195

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


dd if=/root/lubuntu.img bs=1M | gzip > /root/lubuntu-backup.img.gz
gzip -dc /root/lubuntu-backup.img.gz | dd of=/root/lubuntu.img bs=1M status=progress
