#!/bin/bash

export SLOW_DIR="${HOME}/slow"
export SLOW_MP="${SLOW_DIR}/mp"
export SLOW_FS="${SLOW_DIR}/fs"
export SLOW_SZ="${SLOW_DIR}/size"
export SLOW_CONF="${SLOW_DIR}/dmsetup_conf"

# latence de 100ms par défaut
export SLOW_LT=100

function create_slow_device()
{
	size_mb=$1
	mkdir -p $SLOW_MP
	echo $size_mb > $SLOW_SZ
	dd if=/dev/zero of=${SLOW_FS} bs=1M count=${size_mb}
	/sbin/mkfs.ext4 $SLOW_FS
	create_dmsetup_conf $size_mb $SLOW_LT
}

function create_dmsetup_conf()
{
	blocs=$(( $1 * 1024 * 1024 / 512 ))
	delay_ms=$2

	cat > $SLOW_CONF << _EOF_
0 $blocs delay /dev/loop0 0 $delay_ms
_EOF_
}

function reload_slow_device()
{
	lat=$1
	size_mb=`cat $SLOW_SZ`
	umount_slow_device
	create_dmsetup_conf $size_mb $lat
	mount_slow_device
}

function umount_slow_device()
{
	sudo umount $SLOW_MP
	sudo /usr/sbin/dmsetup remove /dev/mapper/delayed-device
	sudo /sbin/losetup --detach /dev/loop0
}

function mount_slow_device()
{
	sudo /sbin/losetup --find --show $SLOW_FS
	sudo /usr/sbin/dmsetup create delayed-device $SLOW_CONF
	sudo mount -o sync /dev/mapper/delayed-device $SLOW_MP
	sudo chown -R postgres: $SLOW_MP
}
