require 'oraclebmc'
require 'base64'


#### Deploy a DSE seed node and DSE OpsCenter
def deploy_dse_opscenter_plus_node(region, compartment_id, subnet_id, availability_domain, image_id, shape, 
	ssh_public_key, opscenter_userdata_sh, node_userdata_sh)
 
   puts("Deploying DSE seed node & DSE OpsCenter: DataStax_Node_plus_OpsCenter ....." )

   # Prepare user_data for Cloud-init process
   dse_user_data = File.open(File.expand_path(node_userdata_sh), "rb").read
   dse_user_data = dse_user_data + "./node.sh" + " " + region + "\n" 
   ops_user_data = File.open(File.expand_path(opscenter_userdata_sh), "rb").read
   user_data = dse_user_data + ops_user_data
   encoded64_str = Base64.urlsafe_encode64(user_data)

   # Prepare BMC instance provisioning details
   request = OracleBMC::Core::Models::LaunchInstanceDetails.new
   request.display_name = "DataStax_Node_plus_OpsCenter"
   request.subnet_id = subnet_id
   request.availability_domain = availability_domain
   request.compartment_id = compartment_id
   request.image_id = image_id
   request.shape = shape
   request.metadata = {'ssh_authorized_keys' => ssh_public_key,
                       'user_data' => encoded64_str}

   api = OracleBMC::Core::ComputeClient.new
   response = api.launch_instance(request)
   instance_id = response.data.id
   response = api.get_instance(instance_id).wait_until(:lifecycle_state, 
		OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:300)
   return get_public_private_ip_addresses(compartment_id, instance_id) 
end 



#### Deploy DSE node 
def deploy_dse_node(region, compartment_id, subnet_id, availability_domain, image_id, shape, 
	ssh_public_key, suffix, node_userdata_sh, seed_node_ip)
   
   puts('Deploying a DSE node: DataStax_Node_' + suffix + ' .....')

   # Prepare user_data for Cloud-init process
   user_data = File.open(File.expand_path(node_userdata_sh), "rb").read
   user_data = user_data + "./node.sh" + " " + region + " " + seed_node_ip + "\n"
   encoded64_str = Base64.urlsafe_encode64(user_data)

   # Prepare BMC instance provisioning details
   request = OracleBMC::Core::Models::LaunchInstanceDetails.new
   request.display_name = "DataStax_Node_" + suffix
   request.subnet_id = subnet_id
   request.availability_domain = availability_domain
   request.compartment_id = compartment_id
   request.image_id = image_id
   request.shape = shape
   request.metadata = {'ssh_authorized_keys' => ssh_public_key,
                       'user_data' => encoded64_str}

   api = OracleBMC::Core::ComputeClient.new
   response = api.launch_instance(request)
   instance_id = response.data.id
#   response = api.get_instance(instance_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:300)
#   return get_public_private_ip_addresses(compartment_id, instance_id)
end


