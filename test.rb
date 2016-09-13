require 'oraclebmc'

# This will load the config file at the default location, and will
# use the tenancy from that config as the compartment in the
# call to list_users.
api = OracleBMC::IdentityApi.new
response = api.list_users(OracleBMC.config.tenancy)
response.data.each { |user| puts user.name }
