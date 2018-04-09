#!/bin/bash

declare -A UBUNTU_RELEASE
UBUNTU_RELEASE=( ["trusty-updates"]="14.04 LTS (Trusty Tahr)" ["xenial-updates"]="16.04 LTS (Xenial Xerus)" ["artful-updates"]="17.10 (Artful Aradvark)" ["bionic"]="18.04 LTS (Bionic Beaver)")

declare -A DEBIAN_RELEASE
DEBIAN_RELEASE=( ["wheezy"]="7 (wheezy)" ["jessie"]="8 (jessie)" ["stretch"]="9 (stretch)" ["buster"]="10 (buster)")

## install grub
mkdir root/EFI
sudo grub-install --target=i386-pc --boot-directory=root/EFI $1
sudo grub-install --target=i386-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
sudo grub-install --target=x86_64-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
cp grub.cfg root/EFI/grub
touch root/EFI/DD-HAN-BOOT-TAG.txt


cd "source"

# ArchLinux Part
curl https://www.archlinux.org/static/netboot/ipxe.8da38b4a9310.pxe -o ipxe.8da38b4a9310.pxe
curl https://www.archlinux.org/static/netboot/ipxe.1e77e6bfd61e.efi -o ipxe.1e77e6bfd61e.efi
mkdir -p ../root/lives/ArchLinux/
cp ipxe* ../root/lives/ArchLinux/


# Ubuntu part
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


# Debian Part

for code in "${!DEBIAN_RELEASE[@]}"; do 
    echo "downloading $code - ${DEBIAN_RELEASE[$code]}"
    curl http://ftp.nl.debian.org/debian/dists/$code/main/installer-i386/current/images/netboot/mini.iso -o $code-i386.iso
    curl http://ftp.nl.debian.org/debian/dists/$code/main/installer-amd64/current/images/netboot/mini.iso -o $code-amd64.iso
done

for code in "${!DEBIAN_RELEASE[@]}"; do 
    echo "extract and patch $code - ${UBUNTU_RELEASE[$code]}"

    7z x $code-amd64.iso -o$code-amd64
    7z x $code-i386.iso -o$code-i386

    if [ $code == "wheezy" ]; then
        mkdir -p $code-i386/boot/grub/
        cp $code-amd64/boot/grub/* $code-i386/boot/grub/
    fi

    sed -i "s/\$prefix\/font.pf2/\/lives\/debian-$code\/amd64\/boot\/grub\/font.pf2/g" $code-amd64/boot/grub/grub.cfg
    sed -i "s/\/isolinux/\/lives\/debian-$code\/amd64/g" $code-amd64/boot/grub/grub.cfg
    sed -i "s/\/linux/\/lives\/debian-$code\/amd64\/linux/g" $code-amd64/boot/grub/grub.cfg
    sed -i "s/\/initrd.gz/\/lives\/debian-$code\/amd64\/initrd.gz/g" $code-amd64/boot/grub/grub.cfg

    rm $code-amd64/boot/grub/efi.img
    rm -rf $code-amd64/boot/grub/x86_64-efi
    rm -rf $code-amd64/\[BOOT\]

    sed -i "s/\$prefix\/font.pf2/\/lives\/debian-$code\/i386\/boot\/grub\/font.pf2/g" $code-i386/boot/grub/grub.cfg
    sed -i "s/\/isolinux/\/lives\/debian-$code\/i386/g" $code-i386/boot/grub/grub.cfg
    sed -i "s/\/linux/\/lives\/debian-$code\/i386\/linux/g" $code-i386/boot/grub/grub.cfg
    sed -i "s/\/initrd.gz/\/lives\/debian-$code\/i386\/initrd.gz/g" $code-i386/boot/grub/grub.cfg

    rm $code-i386/boot/grub/efi.img
    rm -rf $code-i386/boot/grub/i386-efi
    rm -rf $code-i386/\[BOOT\]
done


for code in "${!DEBIAN_RELEASE[@]}"; do 
    echo "copy $code - ${DEBIAN_RELEASE[$code]}"

    mkdir -p ../root/lives/debian-$code/amd64
    mkdir -p ../root/lives/debian-$code/i386

    cp $code-amd64/linux ../root/lives/debian-$code/amd64
    cp $code-amd64/initrd.gz ../root/lives/debian-$code/amd64
    cp -r $code-amd64/boot ../root/lives/debian-$code/amd64

    cp $code-i386/linux ../root/lives/debian-$code/i386
    cp $code-i386/initrd.gz ../root/lives/debian-$code/i386
    cp -r $code-i386/boot ../root/lives/debian-$code/i386

    echo "menuentry \"Debian ${DEBIAN_RELEASE[$code]} 32Bit\" {" >> ../root/EFI/grub/grub.cfg
    echo "	configfile /lives/debian-$code/i386/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
    echo "}" >> ../root/EFI/grub/grub.cfg

    echo "menuentry \"Debian ${DEBIAN_RELEASE[$code]} 64Bit\" {" >> ../root/EFI/grub/grub.cfg
    echo "    configfile /lives/debian-$code/amd64/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
    echo "}" >> ../root/EFI/grub/grub.cfg
done