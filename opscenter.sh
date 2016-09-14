#!/usr/bin/env bash

# This scripts installs and starts OpsCenter.  After it runs you can use LCM to build your cluster.

sudo su
yum -y install wget unzip

wget https://github.com/DSPN/install-datastax-redhat/archive/master.zip
unzip master.zip
cd install-datastax-redhat-master

./bin/os/install_java.sh
./bin/opscenter/install.sh oracle
./bin/opscenter/start.sh
