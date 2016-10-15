require 'oraclebmc'
require 'base64'
require './helper.rb'


# Retrieving input arguments from command line
compartment_name = ARGV[0]
num_nodes = ARGV[1].to_i
ssh_key_full_file_path = ARGV[2]

# User provided input
# Gilbert's compartment_id = 'ocid1.compartment.oc1..aaaaaaaawgpykgu7qgxq3c336hxl7nbtrbgjjbcbrcwp5vhluwglh5mlio2q'
compartment_id = 'ocid1.tenancy.oc1..aaaaaaaaiecpb6fwi33blxe7x7s4btruzrzj77j2javhie3xevuifa2e7fnq'

ssh_public_key = File.open(File.expand_path('/Users/gilbertlau/.ssh/bmc_rsa.pub'), "rb").read

# System-wide input
image_id = 'ocid1.image.oc1.phx.aaaaaaaao5onuwhhahp4vedzamvft73maw45dd4gm57ylglez4zjzhwmzaza'
shape = 'BM.HighIO1.36'
node_userdata_sh ='./extensions/node_userdata.sh'
opscenter_userdata_sh ='./extensions/opscenter_userdata.sh'

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

# Add Ingress/Egress security rules: 0.0.0.0/0 for TCP Protocol (any ports)
vcn_client = OracleBMC::Core::VirtualNetworkClient.new
response = vcn_client.list_security_lists(compartment_id, vcnId)
default_security_list_id = response.data[0].id
update_security_list_details = OracleBMC::Core::Models::UpdateSecurityListDetails.new
ingress_rule_array = Array.new
ingress_rule = OracleBMC::Core::Models::IngressSecurityRule.new
ingress_rule.protocol = 6
ingress_rule.source = '0.0.0.0/0'
ingress_rule_array << ingress_rule
egress_rule_array = Array.new
egress_rule = OracleBMC::Core::Models::EgressSecurityRule.new
egress_rule.protocol = 6
egress_rule.destination = '0.0.0.0/0'
egress_rule_array << egress_rule
update_security_list_details.ingress_security_rules = ingress_rule_array
update_security_list_details.egress_security_rules = egress_rule_array
vcn_client.update_security_list(default_security_list_id, update_security_list_details) 

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



# Create OpsCenter in the first Availability Domain in ads_array
dse_opscenter_node = deploy_dse_opscenter_plus_node(compartment_id, subnet_id[0], 
			ads_array[0], image_id, shape, ssh_public_key, opscenter_userdata_sh, node_userdata_sh)
sleep(30)

# Loop to create a DSE cluster: n number of nodes per Availability Domain
# The OpsCenter node in the first AD will have one DSE node there already so skip one node in the first AD below
seed_node_private_ip = dse_opscenter_node[2]
$ad_index = 0
ads_array.each do |ad|
   subnet = subnet_id[$ad_index]
   $i = 0
   $i += 1 if ad.eql?(ads_array[0]) 

   while $i < num_nodes  do
      deploy_dse_node(compartment_id, subnet, ad, image_id, shape, ssh_public_key, 
		$ad_index.to_s + $i.to_s, node_userdata_sh, seed_node_private_ip)
      sleep(30)
      $i += 1
   end

   $ad_index += 1
end

