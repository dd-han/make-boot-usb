# 開機隨身碟製作 Script

因為多合一開機隨身碟製作起來太麻煩，又得常常更新，所以就寫成 Script 紀錄過程。

```bash
dd if=/dev/zero of=disk.img bs=1M count=4096
echo -e "o\nn\np\n\n\n\n\nt\n\nb\np\nw" | fdisk disk.img
sudo modprobe loop
sudo losetup -f -P disk.img
sudo mkfs.msdos /dev/loop0p1
mkdir root
sudo mount -t vfat /dev/loop0p1 root -o rw,uid=$(id -u),gid=$(id -g)
mkdir -p root/EFI/grub
echo "(hd0)   /dev/loop0" > root/EFI/grub/device.map
echo "(hd0,1)   /dev/loop0p1" >> root/EFI/grub/device.map
bash make.sh /dev/loop0
sudo losetup -d /dev/loop0
sudo rmmod loop
```


sudo qemu-system-x86_64 -hda /dev/sdb