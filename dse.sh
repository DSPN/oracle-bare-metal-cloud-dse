#!/usr/bin/env bash

# This script needs to be run on each node that will run DSE

##### Turn off the firewall
sudo service firewalld stop
sudo chkconfig firewalld off

##### Mount disks

# Install LVM software:
sudo yum -y install lvm2 dmsetup mdadm reiserfsprogs xfsprogs

# Create disk partitions for LVM:
sudo pvcreate /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

# Create volume group upon disk partitions:
sudo vgcreate vg-nvme /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

sudo lvcreate --name lv --size 11.6T vg-nvme
sudo mkfs.ext4 /dev/vg-nvme/lv

sudo mkdir /cassandra
sudo mount /dev/vg-nvme/lv /cassandra

sudo chmod 777 /cassandra
