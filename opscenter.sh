#!/usr/bin/env bash

# This scripts installs and starts OpsCenter.  After it runs you can use LCM to build your cluster.

curl https://raw.githubusercontent.com/DSPN/install-datastax-redhat/master/bin/opscenter/install.sh > install.sh
curl https://raw.githubusercontent.com/DSPN/install-datastax-redhat/master/bin/opscenter/start.sh > start.sh

chmod +x install.sh
chmod +x opscenter.sh

./install.sh oracle
./start.sh
