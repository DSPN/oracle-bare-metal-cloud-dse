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

First, you'll need to creat a Cloud Network.  In this case we've called ours "mycloudnetwork."  When you create the Cloud Network, it creates three subnets, one in each availability domain.  We are going to map availability domains to racks.

We are going to use the root compartment that is created by default.  For the compartment ID, specify your "Tenancy ID."

