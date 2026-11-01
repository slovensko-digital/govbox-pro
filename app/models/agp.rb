module Agp
  def self.table_name_prefix
    "agp_"
  end

  def self.api_for(tenant)
    SigningEnvironment.signing_client.api(tenant: tenant)
  end
end
