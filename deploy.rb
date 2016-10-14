require 'oraclebmc'
require 'base64'
require './helper.rb'



# Retrieving input arguments from command line
compartment_name = ARGV[0]
num_nodes = ARGV[1].to_i


# User provided input
compartment_id = 'ocid1.compartment.oc1..aaaaaaaawgpykgu7qgxq3c336hxl7nbtrbgjjbcbrcwp5vhluwglh5mlio2q'
ssh_public_key = File.open(File.expand_path('/Users/gilbertlau/BMC/bmc_rsa.pub'), "rb").read


# System-wide input
image_id = 'ocid1.image.oc1.phx.aaaaaaaao5onuwhhahp4vedzamvft73maw45dd4gm57ylglez4zjzhwmzaza'
shape = 'BM.HighIO1.36'
dse_sh ='dse.sh'
opscenter_sh ='opscenter.sh'

# Retrieve Availability Domain
identity_client = OracleBMC::Identity::IdentityClient.new
response = identity_client.list_availability_domains(compartment_id)
#arr = response.data.each { |user| puts user.name } 
ads_array = Array.new
ads_array = response.data.collect{ |user| user.name }


###################################################################
#
# Set up Virtual Cloud Network 
#
###################################################################

# Create a Virtual Cloud Network for the DataStax Enterprise Cluster 
vcn_details = OracleBMC::Core::Models::CreateVcnDetails.new
vcn_details.cidr_block = '10.0.0.0/16'
vcn_details.compartment_id = compartment_id
vcn_details.display_name = "DataStax_VCN_001"
vcn_client = OracleBMC::Core::VirtualNetworkClient.new
response = vcn_client.create_vcn(vcn_details)
vcnId = response.data.id

# Create an Internet Gateway for the Virtual Cloud Network
internet_gateway_details = OracleBMC::Core::Models::CreateInternetGatewayDetails.new
internet_gateway_details.compartment_id = compartment_id
internet_gateway_details.display_name = 'DS_Internet_Gateway'
internet_gateway_details.is_enabled = true
internet_gateway_details.vcn_id = vcnId
response = vcn_client.create_internet_gateway(internet_gateway_details)
internet_gateway_id = response.data.id

# Add route rule - CIDR Block: 0.0.0.0/0 to default route table of the Virtual Cloud Network
response = vcn_client.list_route_tables(compartment_id, vcnId) 
rt_id_array = response.data.collect{ |user| user.id }
route_rule = OracleBMC::Core::Models::RouteRule.new
route_rule.cidr_block = '0.0.0.0/0'
route_rule.network_entity_id = internet_gateway_id
route_rule_arr = Array.new
route_rule_arr << route_rule
update_rt_details = OracleBMC::Core::Models::UpdateRouteTableDetails.new
update_rt_details.route_rules = route_rule_arr
vcn_client.update_route_table(rt_id_array[0], update_rt_details)

# Create a subnet in each Availability Domain
$x = 0
subnet_id = Array.new
ads_array.each do |ad|
   vcn_subnet_details = OracleBMC::Core::Models::CreateSubnetDetails.new
   vcn_subnet_details.availability_domain = ad
   vcn_subnet_details.cidr_block= '10.0.' + $x.to_s + '.0/24'
   vcn_subnet_details.compartment_id = compartment_id
   vcn_subnet_details.vcn_id = vcnId
   vcn_subnet_details.display_name = ad
   vcn_client = OracleBMC::Core::VirtualNetworkClient.new
   response = vcn_client.create_subnet(vcn_subnet_details)
   subnet_id << response.data.id
   
   $x += 1
end


# Reading from dse.sh
user_data = File.open(File.expand_path('/Users/gilbertlau/Documents/GitHub/oracle-bare-metal-cloud-dse/dse.sh'), "rb").read
encoded64_str = Base64.urlsafe_encode64(user_data)


# Loop to create a DSE cluster
$i = 0
instance_array = Array.new
while $i < num_nodes  do
   puts("Deploying machine number #$i" )

   request = OracleBMC::Core::Models::LaunchInstanceDetails.new
   request.display_name = "DataStax#$i"
   request.subnet_id = subnet_id[$i]
   request.availability_domain = ads_array[$i]
   request.compartment_id = compartment_id
   request.image_id = image_id
   request.shape = shape
   request.metadata = {'ssh_authorized_keys' => ssh_public_key,
		       'user_data' => encoded64_str}
   api = OracleBMC::Core::ComputeClient.new
   response = api.launch_instance(request)
   instance_id = response.data.id
   response = api.get_instance(instance_id).wait_until(:lifecycle_state, OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:900)
   instance_array << instance_id
   $i += 1
end


# Generate a list of public and private ip addresses of BMC hosts
host_ips_list = Array.new
instance_array.each do |instance_id|
   host_ips_list << get_public_private_ip_addresses(compartment_id, instance_id)   
end

puts(host_ips_list)


# Spinning up OpsCenter



# Spinning
