#!/bin/sh

plugin_chroot_file=$2/chroot_file/
root_path=$1
root_bin=$root_path/bin
root_lib=$root_path/lib
root_user=$root_path/usr
root_proc=$root_path/proc
root_dev=$root_path/dev

check_and_umount(){
        exist=`df -h |grep $1`
        if $exist ;then
                umount $1 -f
        fi
}

check_and_umount $root_lib
check_and_umount $root_bin
check_and_umount $root_proc
check_and_umount $root_dev

mkdir -p $root_bin
mkdir -p $root_lib
mkdir -p $root_path/etc
mkdir -p $root_proc

mount --bind -r $plugin_chroot_file/lib $root_lib
mount --bind -r $plugin_chroot_file/bin $root_bin
mount --bind -r /proc $root_proc

cp /tmp/TZ $root_path/etc/TZ
cp /etc/passwd $root_path/etc/passwd
cp /etc/group $root_path/etc/group
