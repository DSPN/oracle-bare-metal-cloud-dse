#!/usr/bin/env bash

# This scripts installs and starts OpsCenter.  After it runs you can use LCM to build your cluster.

curl https://github.com/DSPN/install-datastax-redhat/archive/master.zip
unzip master.zip

sudo su

./bin/os/install_java.sh
./bin/opscenter/install.sh oracle
./bin/opscenter/start.sh
