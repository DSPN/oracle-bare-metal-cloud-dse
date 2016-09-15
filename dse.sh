#!/usr/bin/env bash

# This script needs to be run on each node that will run DSE

# Turn off the firewall
sudo service firewalld stop
sudo chkconfig firewalld off

# Mount disks
sudo pvcreate /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
sudo vgcreate vg-nvme /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n /dev/nvme3n1

sudo lvcreate --name lv --size 12.8T vg-nvme
sudo mount /dev/vg-nvme/lv /cassandra
