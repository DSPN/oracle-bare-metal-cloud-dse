#!/usr/bin/env bash

# This script needs to be run on each node that will run DSE

##### Turn off the firewall

service firewalld stop

chkconfig firewalld off

##### Mount disks

# Install LVM software:

yum -y install lvm2 dmsetup mdadm reiserfsprogs xfsprogs

# Create disk partitions for LVM:

pvcreate /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

# Create volume group upon disk partitions:

vgcreate vg-nvme /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

lvcreate --name lv --size 11.6T vg-nvme

mkfs.ext4 /dev/vg-nvme/lv

mkdir /cassandra

mount /dev/vg-nvme/lv /cassandra

chmod 777 /cassandra
