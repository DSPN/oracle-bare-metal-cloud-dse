require 'oraclebmc'

subnet_id = ['ocid1.subnet.oc1.phx.aaaaaaaaf6kowbejussojcfenl5djacznsdwaivxfqzskadvbjs7m7534qxa','ocid1.subnet.oc1.phx.aaaaaaaa4wvkz5cuz37iafelqsqf7aqx3zlxc52jkudcxiaxsgtgif5ytsga','ocid1.subnet.oc1.phx.aaaaaaaayezdgxnv4tlp7dt55cl3txtxkvtkbf63shhtwx5loulxflgflgja']
availability_domain = ['FcAL:PHX-AD-1','FcAL:PHX-AD-2','FcAL:PHX-AD-3']
compartment_id = 'ocid1.tenancy.oc1..aaaaaaaaiecpb6fwi33blxe7x7s4btruzrzj77j2javhie3xevuifa2e7fnq'

ssh_public_key = File.open(File.expand_path('/Users/gilbertlau/BMC/bmc_rsa.pub'), "rb").read

$i = 0
while $i < 1  do
   puts("Deploying machine number #$i" )

   request = OracleBMC::LaunchInstanceRequest.new
   request.display_name = "datastax#$i"
   request.subnet_id = subnet_id[$i]
   request.availability_domain = availability_domain[$i]
   request.compartment_id = compartment_id
   request.image_id = 'Oracle-Linux-7.2-2016.09.18-0'
   request.shape = 'BM.HighIO1.36'
   request.metadata = {'ssh_authorized_keys' => ssh_public_key}

   api = OracleBMC::ComputeApi.new
   response = api.launch_instance(request)

   $i +=1
end
