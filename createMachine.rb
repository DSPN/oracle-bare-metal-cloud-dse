require 'oraclebmc'

subnet_id1 = 'ocid1.subnet.oc1.phx.aaaaaaaaf6kowbejussojcfenl5djacznsdwaivxfqzskadvbjs7m7534qxa'
subnet_id2 = 'ocid1.subnet.oc1.phx.aaaaaaaa4wvkz5cuz37iafelqsqf7aqx3zlxc52jkudcxiaxsgtgif5ytsga'
subnet_id3 = 'ocid1.subnet.oc1.phx.aaaaaaaayezdgxnv4tlp7dt55cl3txtxkvtkbf63shhtwx5loulxflgflgja'

compartment_id = 'ocid1.tenancy.oc1..aaaaaaaaiecpb6fwi33blxe7x7s4btruzrzj77j2javhie3xevuifa2e7fnq'

availability_domain1 = 'FcAL:PHX-AD-1'
availability_domain2 = 'FcAL:PHX-AD-2'
availability_domain3 = 'FcAL:PHX-AD-3'

ssh_public_key = File.open(File.expand_path('/Users/ben/.ssh/id_rsa.pub'), "rb").read

request = OracleBMC::LaunchInstanceDetails.new
request.availability_domain = availability_domain1
request.compartment_id = compartment_id
request.display_name = 'my_instance'
request.image_id = 'ol7.2-base-0.0.2'
request.shape = 'BM.Standard1.36'
request.subnet_id = subnet_id1
request.metadata = {'ssh_authorized_keys' => ssh_public_key}

api = OracleBMC::ComputeApi.new
response = api.launch_instance(request)
response = api.get_instance(response.data.id).wait_until(:lifecycle_state, OracleBMC::Instance::LIFECYCLE_STATE_RUNNING, max_wait_seconds:300)
