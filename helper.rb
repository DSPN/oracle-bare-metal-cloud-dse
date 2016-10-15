require 'oraclebmc'
require 'base64'


# Obtaining the public and private IP addresses of a BMC instance
def get_public_private_ip_addresses(compartment_id, instance_id)
   compute_client = OracleBMC::Core::ComputeClient.new
   response = compute_client.list_vnic_attachments(compartment_id, {instance_id: instance_id})
   vnic_array = response.data.collect{ |user| user.vnic_id }
   vnic_id = vnic_array[0]
   vcn_client = OracleBMC::Core::VirtualNetworkClient.new
   vnic_record = vcn_client.get_vnic(vnic_id)
   public_ip = vnic_record.data.public_ip
   private_ip = vnic_record.data.private_ip
   ip_array = Array.new
   ip_array << instance_id
   ip_array << public_ip
   ip_array << private_ip
   return ip_array
end



# Deploy DSE OpsCenter
def deploy_dse_opscenter_plus_node(compartment_id, subnet_id, availability_domain, image_id, shape, ssh_public_key, opscenter_userdata_sh, node_userdata_sh) 
   puts("Deploying OpsCenter..." )
 
   dse_user_data = File.open(File.expand_path(node_userdata_sh), "rb").read
   dse_user_data = dse_user_data + "./node.sh" + "\n" 
   ops_user_data = File.open(File.expand_path(opscenter_userdata_sh), "rb").read
   user_data = dse_user_data + ops_user_data
   encoded64_str = Base64.urlsafe_encode64(user_data)
 
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
   response = api.get_instance(instance_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:60)
   return get_public_private_ip_addresses(compartment_id, instance_id) 
end 



# Deploy DSE node 
def deploy_dse_node(compartment_id, subnet_id, availability_domain, image_id, shape, ssh_public_key, suffix, node_userdata_sh, seed_node_ip)
   puts('Deploying DSE node...' + suffix )

   user_data = File.open(File.expand_path(node_userdata_sh), "rb").read
   user_data = user_data + "./node.sh" + " " + seed_node_ip + "\n"
   encoded64_str = Base64.urlsafe_encode64(user_data)

   request = OracleBMC::Core::Models::LaunchInstanceDetails.new
   request.display_name = "DataStax_Node" + suffix
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
#   response = api.get_instance(instance_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:900)
#   return get_public_private_ip_addresses(compartment_id, instance_id)
end


