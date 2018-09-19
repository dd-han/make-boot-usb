#!/bin/bash
# ENABLE_GRUB="TRUE"
# ENABLE_SYSLINUX="TRUE"

declare -A UBUNTU_RELEASE
UBUNTU_RELEASE=( ["trusty-updates"]="14.04 LTS (Trusty Tahr)" ["xenial-updates"]="16.04 LTS (Xenial Xerus)" ["artful-updates"]="17.10 (Artful Aradvark)" ["bionic-updates"]="18.04 LTS (Bionic Beaver)")

declare -A DEBIAN_RELEASE
DEBIAN_RELEASE=( ["wheezy"]="7 (wheezy)" ["jessie"]="8 (jessie)" ["stretch"]="9 (stretch)" ["buster"]="10 (buster)")

####
## boot loader
if [ "$ENABLE_GRUB" == "TRUE" ]; then 
    echo install GRUB
    mkdir root/EFI
    touch root/EFI/DD-HAN-BOOT-TAG.txt
    sudo grub-install --target=i386-pc --boot-directory=root/EFI $1
    sudo grub-install --target=i386-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
    sudo grub-install --target=x86_64-efi --removable --boot-directory=root/EFI --efi-directory=root --grub-mkdevicemap=root/EFI/grub/device.map $1
    cp grub.cfg root/EFI/grub
fi

if [ "$ENABLE_SYSLINUX" == "TRUE" ]; then
    echo install SYSLINUX
    cp syslinux.cfg root/
    sudo extlinux --install root
    cp /usr/lib/syslinux/bios/*.c32 root
    sudo dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/bios/mbr.bin of=$1
fi


cd "source"

####
## Hiren's BootCD (DOS)
if [ -f "Hirens.BootCD.15.2.zip" ]; then
    if [ ! -d "hirens" ]; then
        7z x Hirens.BootCD.15.2.zip -ohirens
        7z x hirens/Hiren\'s.BootCD.15.2.iso -ohirens/iso
    fi
    cp -a hirens/iso/HBCD ../root
fi

####
## Parted Magic
if [ -f pmagic* ]; then
    if [ ! -d pmagic ]; then
        7z x pmagic* -opmagic
        mkdir -p ../root/lives/pmagic/
        cp -a pmagic/pmagic ../root/lives/pmagic/

        sed -i "s/settings=\"[^\"]*/& directory=\/lives\/pmagic/g" pmagic/boot/grub/grub.cfg
        sed -i 's/\/pmagic\//\/lives\/pmagic&/g' pmagic/boot/grub/grub.cfg
        sed -i 's/\/boot\//\/lives\/pmagic&/g' pmagic/boot/grub/grub.cfg

        rm -rf pmagic/boot/grub/x86_64-efi
    fi
    cp -a pmagic/boot ../root/lives/pmagic/
fi

####
## ArchLinux Part
if [ ! -f ipxe.8da38b4a9310.pxe ]; then
    curl https://www.archlinux.org/static/netboot/ipxe.8da38b4a9310.pxe -o ipxe.8da38b4a9310.pxe
fi

if [ ! -f ipxe.1e77e6bfd61e.efi ]; then
    curl https://www.archlinux.org/static/netboot/ipxe.1e77e6bfd61e.efi -o ipxe.1e77e6bfd61e.efi
fi
mkdir -p ../root/lives/ArchLinux/
cp ipxe* ../root/lives/ArchLinux/


####
## Ubuntu part
for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "downloading $code - ${UBUNTU_RELEASE[$code]}"
    if [ ! -f "$code-i386.iso" ]; then
        curl http://archive.ubuntu.com/ubuntu/dists/$code/main/installer-i386/current/images/netboot/mini.iso -o $code-i386.iso
    fi
    if [ ! -f "$code-amd64.iso" ]; then
        curl http://archive.ubuntu.com/ubuntu/dists/$code/main/installer-amd64/current/images/netboot/mini.iso -o $code-amd64.iso
    fi

done

for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "extract and patch $code - ${UBUNTU_RELEASE[$code]}"

    if [ ! -d "$code-amd64" ]; then
        7z x $code-amd64.iso -o$code-amd64
        7z x $code-i386.iso -o$code-i386

        sed -i "s/\/boot\/grub\/font.pf2/\/lives\/ubuntu-$code\/amd64\/boot\/grub\/font.pf2/g" $code-amd64/boot/grub/grub.cfg
        sed -i "s/\/linux/\/lives\/ubuntu-$code\/amd64\/linux/g" $code-amd64/boot/grub/grub.cfg
        sed -i "s/\/initrd.gz/\/lives\/ubuntu-$code\/amd64\/initrd.gz/g" $code-amd64/boot/grub/grub.cfg

        for cfg in `ls $code-amd64/*.cfg`;do
            sed -i "s/[^ ]*\.cfg/lives\/ubuntu-$code\/amd64\/&/g" "$cfg"
            sed -i "s/[^ ]*\.png/lives\/ubuntu-$code\/amd64\/&/g" "$cfg"
            sed -i "s/kernel linux/kernel lives\/ubuntu-$code\/amd64\/linux/g" "$cfg"
            sed -i "s/initrd.gz/lives\/ubuntu-$code\/amd64\/&/g" "$cfg"
        done

        rm -rf $code-amd64/boot/grub/x86_64-efi
        rm -rf $code-amd64/boot/grub/efi.img
        rm -rf $code-amd64/\[BOOT\]

        cp -r $code-amd64/boot $code-i386/boot
        sed -i "s/$code\/amd64/$code\/i386/g" $code-i386/boot/grub/grub.cfg
        for cfg in `ls $code-i386/*.cfg`;do
            sed -i "s/[^ ]*\.cfg/lives\/ubuntu-$code\/i386\/&/g" "$cfg"
            sed -i "s/[^ ]*\.png/lives\/ubuntu-$code\/i386\/&/g" "$cfg"
            sed -i "s/kernel linux/kernel lives\/ubuntu-$code\/i386\/linux/g" "$cfg"
            sed -i "s/initrd.gz/lives\/ubuntu-$code\/i386\/&/g" "$cfg"
        done
        rm -rf $code-i386/\[BOOT\]
    fi
done


for code in "${!UBUNTU_RELEASE[@]}"; do 
    echo "copy $code - ${UBUNTU_RELEASE[$code]}"

    mkdir -p ../root/lives/ubuntu-$code/amd64
    mkdir -p ../root/lives/ubuntu-$code/i386

    cp $code-amd64/linux ../root/lives/ubuntu-$code/amd64
    cp $code-amd64/initrd.gz ../root/lives/ubuntu-$code/amd64
    cp -r $code-amd64/boot ../root/lives/ubuntu-$code/amd64
    cp -r $code-amd64/*.{cfg,txt,png} ../root/lives/ubuntu-$code/amd64

    cp $code-i386/linux ../root/lives/ubuntu-$code/i386
    cp $code-i386/initrd.gz ../root/lives/ubuntu-$code/i386
    cp -r $code-i386/boot ../root/lives/ubuntu-$code/i386
    cp -r $code-i386/*.cfg ../root/lives/ubuntu-$code/i386
    cp -r $code-i386/*.txt ../root/lives/ubuntu-$code/i386

    ## GRUB2 config
    if [ "$ENABLE_GRUB" == "TRUE" ]; then 

        echo "menuentry \"Ubuntu ${UBUNTU_RELEASE[$code]} 32Bit\" {" >> ../root/EFI/grub/grub.cfg
        echo "	configfile /lives/ubuntu-$code/i386/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
        echo "}" >> ../root/EFI/grub/grub.cfg

        echo "menuentry \"Ubuntu ${UBUNTU_RELEASE[$code]} 64Bit\" {" >> ../root/EFI/grub/grub.cfg
        echo "    configfile /lives/ubuntu-$code/amd64/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
        echo "}" >> ../root/EFI/grub/grub.cfg
    fi

    if [ "$ENABLE_SYSLINUX" == "TRUE" ]; then 
        ## syslinux CONFIG
        echo "LABEL Ubuntu ${UBUNTU_RELEASE[$code]} 32Bit" >> ../root/syslinux.cfg
        echo "    KERNEL vesamenu.c32" >> ../root/syslinux.cfg
        echo "    APPEND lives/ubuntu-$code/i386/menu.cfg" >> ../root/syslinux.cfg

        echo "LABEL Ubuntu ${UBUNTU_RELEASE[$code]} 64Bit" >> ../root/syslinux.cfg
        echo "    KERNEL vesamenu.c32" >> ../root/syslinux.cfg
        echo "    APPEND lives/ubuntu-$code/amd64/menu.cfg" >> ../root/syslinux.cfg
    fi
done


####
## Debian Part
for code in "${!DEBIAN_RELEASE[@]}"; do 
  echo "downloading $code - ${DEBIAN_RELEASE[$code]}"
  if [ ! -f "$code-i386.iso" ]; then
    curl http://ftp.nl.debian.org/debian/dists/$code/main/installer-i386/current/images/netboot/mini.iso -o $code-i386.iso
  fi
  if [ ! -f "$code-amd64.iso" ]; then
    curl http://ftp.nl.debian.org/debian/dists/$code/main/installer-amd64/current/images/netboot/mini.iso -o $code-amd64.iso
  fi
done

for code in "${!DEBIAN_RELEASE[@]}"; do 
    echo "extract and patch $code - ${UBUNTU_RELEASE[$code]}"

    if [ ! -d "$code-amd64" ]; then
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
    fi
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

    ## GRUB2 config
    if [ "$ENABLE_GRUB" == "TRUE" ]; then 

        echo "menuentry \"Debian ${DEBIAN_RELEASE[$code]} 32Bit\" {" >> ../root/EFI/grub/grub.cfg
        echo "	configfile /lives/debian-$code/i386/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
        echo "}" >> ../root/EFI/grub/grub.cfg

        echo "menuentry \"Debian ${DEBIAN_RELEASE[$code]} 64Bit\" {" >> ../root/EFI/grub/grub.cfg
        echo "    configfile /lives/debian-$code/amd64/boot/grub/grub.cfg" >> ../root/EFI/grub/grub.cfg
        echo "}" >> ../root/EFI/grub/grub.cfg
    fi

    if [ "$ENABLE_SYSLINUX" == "TRUE" ]; then 
        ## syslinux CONFIG
        echo "LABEL Debian ${DEBIAN_RELEASE[$code]} 32Bit" >> ../root/syslinux.cfg
        echo "    KERNEL vesamenu.c32" >> ../root/syslinux.cfg
        echo "    APPEND lives/debian-$code/i386/menu.cfg" >> ../root/syslinux.cfg

        echo "LABEL Debian ${DEBIAN_RELEASE[$code]} 64Bit" >> ../root/syslinux.cfg
        echo "    KERNEL vesamenu.c32" >> ../root/syslinux.cfg
        echo "    APPEND lives/debian-$code/amd64/menu.cfg" >> ../root/syslinux.cfg
    fi
done
