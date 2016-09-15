#!/usr/bin/env bash

sudo pvcreate /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
sudo vgcreate vg-nvme /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n /dev/nvme3n1

sudo lvcreate --name lv --size 12.8T vg-nvme
sudo mount /dev/vg-nvme/lv /cassandra
