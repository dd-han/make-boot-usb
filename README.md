# 開機隨身碟製作 Script

因為多合一開機隨身碟製作起來太麻煩，又得常常更新，所以就寫成 Script 紀錄過程。

不使用實體隨身碟執行
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

使用實體隨身碟
```bash
sudo mount -t vfat /dev/sdb1 root -o rw,uid=$(id -u),gid=$(id -g)
bash make.sh /dev/sdb1
```


測試開機的指令（好像會記憶體不足）
```bash
sudo qemu-system-x86_64 -hda /dev/sdb
```