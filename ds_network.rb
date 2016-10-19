require 'oraclebmc'
require 'base64'



#### Set security rule
def set_security_rule(protocol_code, min_port, max_port)

   tcp_port_range = OracleBMC::Core::Models::PortRange.new
   tcp_port_range = {'min' => min_port, 'max' => max_port}
   tcp_options = OracleBMC::Core::Models::TcpOptions.new
   tcp_options.destination_port_range = tcp_port_range
   ingress_rule = OracleBMC::Core::Models::IngressSecurityRule.new
   ingress_rule.protocol = protocol_code
   ingress_rule.source = '0.0.0.0/0'
   ingress_rule.tcp_options = tcp_options

   return ingress_rule
end



#### Obtain the public and private IP addresses of a BMC instance
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




