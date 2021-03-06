# oracle-bare-metal-cloud-dse
Scripts and instructions to deploy DataStax Enterprise (DSE) to Oracle Bare Metal Cloud

## Prerequisites

You will need to install the Ruby SDK for Oracle Bare Metal Cloud.

Login to https://console.us-az-phoenix-1.oracleiaas.com/#/a/  The Ruby SDK is available [here](https://docs.us-phoenix-1.oraclecloud.com/tools/ruby/latest/download/oracle-bmcs-ruby-sdk.zip).  Doc is available at [here](https://docs.us-az-phoenix-1.oracleiaas.com/tools/ruby/latest/frames.html).  Download the SDK and install it using the command:

```
gem install oraclebmc-1.1.1.gem
```

You will now need to create a config file for the SDK as detailed in the [documentation](https://docs.us-az-phoenix-1.oracleiaas.com/tools/ruby/latest/index.html#label-Configuring+the+SDK).  The default location and file name of the config file are \<your home directory\>/.oraclebmc and config respectively.

Next download our git project as follows:

```
git clone https://github.com/DSPN/oracle-bare-metal-cloud-dse
cd oracle-bare-metal-cloud-dse
```

You can now run this command to verify your setup:

    ruby test.rb

It should return a list of users belonging to your Oracle Bare Metal Cloud tenancy like the following:

![](./img/test_rb.png)

## Deploying DataStax Enterprise cluster and DataStax OpsCenter

At this point, you can run the following script to deploy your DataStax Enterprise cluster and DataStax OpsCenter.  You will need to pass in three arguments to the script:

* Compartment ID
* Number of nodes in each Availability Domain
* Your SSH public key's full file path name

```
./deploy.rb  <compartment_id>  <number of nodes>  <ssh_key_full_path_name>

For example,  ./deploy.rb  ocid1.compartment.oc1..aaaaaaawgpykgu7qgxq3c369hxl7nbtrbgjjbcbrcwp5vhluwglh5mlcm2q  1  /Users/gilbertlau/.ssh/bmc_rsa.pub
```

*If you see this error message: "/usr/local/lib/ruby/gems/2.3.0/gems/oraclebmc-0.8.0/lib/oraclebmc/api_client.rb:163:in `call_api_inner': The limit for this tenancy has been exceeded. (OracleBMC::ServiceError)" when running the above command, you are likely run into Service Limits for your tenancy, you can increase the service limits by following the steps [here](https://docs.us-phoenix-1.oraclecloud.com/Content/General/Concepts/servicelimits.htm).*

The whole process will take about 15 to 20 minutes long depending on the number of nodes to deploy.  You can now go back to the Oracle BareM Metal Cloud console to check if all your nodes are up and running.  Once 10 to 15 minutes have passed, you can try to point your browser at port 8888 of the public IP address of node named "DataStax_Node_plus_OpsCenter".  Initially, you might see the cluster containing only one DSE node.  You will gradually see more nodes coming up as they are being provisioned.

![](./img/opscenter_6_nodes.png)

## Testing the Cluster

You can ssh into one of your DSE cluster nodes and try running [Cassandra Stress](https://docs.datastax.com/en/cassandra/3.x/cassandra/tools/toolsCStress.html) as follows:

```
cassandra-stress write n=1000000 cl=QUORUM -rate threads=50 -mode native cql3 user=cassandra password=cassandra -node <any DSE node internal IP address>  -schema "replication(factor=3)"
```

## Deleting the Cluster and its associated virtual cloud network

To delete the cluster, login to Oracle Bare Metal Cloud console and click "Terminate" on each node and the virtual cloud network named "ds_vcn_network" which was created as part of your DSE cluster deployment.
