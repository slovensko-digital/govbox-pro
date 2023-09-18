class Admin::Tenants::TenantsListRowComponent < ViewComponent::Base
  def initialize(tenant)
    @tenant = tenant
  end
end
