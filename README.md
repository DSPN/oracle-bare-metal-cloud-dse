# oracle-bare-metal-cloud-dse
Scripts and instructions to deploy DSE to Oracle Bare Metal Cloud

## Prerequisites

You will need to install the Ruby SDK for Oracle Bare Metal Cloud.

Login to https://console.us-az-phoenix-1.oracleiaas.com/#/a/  The Ruby SDK is available [here](https://docs.us-az-phoenix-1.oracleiaas.com/tools/ruby/latest/download/oraclebmc-0.6.1.gem).  Doc is available at [here](https://docs.us-az-phoenix-1.oracleiaas.com/tools/ruby/latest/frames.html).  Download the SDK and install it using the command:

    gem install oraclebmc-0.6.1.gem

If all went well you should see:

![](./img/geminstall.png)

You will now need to create a config file for the SDK as detailed in the documentation.

At this point your Ruby SDK should be all set up.  You can run this command to test if your setup is correct:

    irb test.rb

## Setting up Instances

First, you'll need to create a Cloud Network.  In this case we've called ours "mycloudnetwork."  When you create the Cloud Network, it creates three subnets, one in each availability domain.  We are going to map availability domains to racks.

We are going to use the root compartment that is created by default.  For the compartment ID, specify your "Tenancy ID."

You will need to edit the subnet_id, compartment_id and ssh_public_key to the values in your environment.

When complete you can run the following command to deploy your cluster:

    irb createMachine.rb
    
On completion you can log into the Console to view your machines.

## Installing DataStax Enterprise

Now that your instances are running, we are going to install DataStax Enterprise (DSE).  This will be a two step process:
* Install OpsCenter
* Use OpsCenter Lifecycle Manager (LCM) to install and configure DSE on each node

You will need to open a terminal session to the each machine.  To ssh to the machine, find its public IP in the console and then run the command:

    ssh -i ~/.ssh/id_rsa opc@<IP Address>

Oracle Linux runs iptables by default.  We can stop iptables by running the following command.  You will need to do this on each node.

    curl https://raw.githubusercontent.com/DSPN/oracle-bare-metal-cloud-dse/master/bin/dse.sh > dse.sh
    chmod +x dse.sh
    ./dse.sh

Now, on the first machine, datastax0, run these commands to get an install script that will set up OpsCenter:

    curl https://raw.githubusercontent.com/DSPN/oracle-bare-metal-cloud-dse/master/bin/opscenter.sh > opscenter.sh
    chmod +x opscenter.sh
    ./opscenter.sh

Ok, now OpsCenter is installed and running.  At this point we need to open port 8888 in the console so we can access OpsCenter and run LCM.

At this point OpsCenter should be accessible on port 8888 of the public IP address of node datastax0:

![](./img/welcometoopscenter.png)

Now we are going to click "Create a new cluster" and use LCM to deploy DSE to each of our three nodes.  When complete your cluster should show three nodes:

![](./img/opscentercluster.png)

## Configuring Data Directory

You will need to mount and configure your data drives to make use of the NVME drives on these machines.

First, we need to ssh to each node and run the following commands to mount the drive:

    asd

## Deleting the Cluster

To delete the cluster, login to the console and click "terminate" on each node.
