#!/usr/bin/env bash

# This scripts installs and starts OpsCenter.  After it runs you can use LCM to build your cluster.

wget https://raw.githubusercontent.com/DSPN/install-datastax-ubuntu/master/bin/opscenter/install.sh
wget https://raw.githubusercontent.com/DSPN/install-datastax-ubuntu/master/bin/opscenter/start.sh

./install.sh oracle
./start.sh
