#!/bin/bash

declare -A UBUNTU_RELEASE
UBUNTU_RELEASE=( ["trusty-updates"]="14.04 LTS (Trusty Tahr)" ["xenial-updates"]="16.04 LTS (Xenial Xerus)" ["artful-updates"]="17.10 (Artful Aradvark)" ["bionic"]="18.04 LTS (Bionic Beaver)")


## install grub
sudo grub-install --target=i386-pc --boot-directory=root/EFI $1
sudo grub-install --target=i386-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
sudo grub-install --target=x86_64-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
cp grub.cfg root/EFI/grub


## put ubuntu images

cd "source"

for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "downloading $code - ${UBUNTU_RELEASE[$code]}"
    curl http://archive.ubuntu.com/ubuntu/dists/$code/main/installer-i386/current/images/netboot/mini.iso -o $code-i386.iso
    curl http://archive.ubuntu.com/ubuntu/dists/$code/main/installer-amd64/current/images/netboot/mini.iso -o $code-amd64.iso

done

for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "extract and patch $code - ${UBUNTU_RELEASE[$code]}"

    7z x $code-amd64.iso -o$code-amd64
    7z x $code-i386.iso -o$code-i386

    sed -i "s/\/boot\/grub\/font.pf2/\/lives\/ubuntu-$code\/amd64\/boot\/grub\/font.pf2/g" $code-amd64/boot/grub/grub.cfg
    sed -i "s/\/linux/\/lives\/ubuntu-$code\/amd64\/linux/g" $code-amd64/boot/grub/grub.cfg
    sed -i "s/\/initrd.gz/\/lives\/ubuntu-$code\/amd64\/initrd.gz/g" $code-amd64/boot/grub/grub.cfg

    rm -rf $code-amd64/boot/grub/x86_64-efi
    rm -rf $code-amd64/boot/grub/efi.img
    rm -rf $code-amd64/\[BOOT\]

    cp -r $code-amd64/boot $code-i386/boot
    sed -i "s/$code\/amd64/$code\/i386/g" $code-i386/boot/grub/grub.cfg
    rm -rf $code-i386/\[BOOT\]
done


for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "copy $code - ${UBUNTU_RELEASE[$code]}"

    mkdir -p ../root/lives/ubuntu-$code/amd64
    mkdir -p ../root/lives/ubuntu-$code/i386

    cp $code-amd64/linux ../root/lives/ubuntu-$code/amd64
    cp $code-amd64/initrd.gz ../root/lives/ubuntu-$code/amd64
    cp -r $code-amd64/boot ../root/lives/ubuntu-$code/amd64

    cp $code-i386/linux ../root/lives/ubuntu-$code/i386
    cp $code-i386/initrd.gz ../root/lives/ubuntu-$code/i386
    cp -r $code-i386/boot ../root/lives/ubuntu-$code/i386

    echo "menuentry \"Ubuntu ${UBUNTU_RELEASE[$code]} 32Bit\" {" >> ../root/EFI/grub/grub.cfg
    echo "	configfile /lives/ubuntu-$code/i386/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
    echo "}" >> ../root/EFI/grub/grub.cfg

    echo "menuentry \"Ubuntu ${UBUNTU_RELEASE[$code]} 64Bit\" {" >> ../root/EFI/grub/grub.cfg
    echo "    configfile /lives/ubuntu-$code/amd64/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
    echo "}" >> ../root/EFI/grub/grub.cfg
done

