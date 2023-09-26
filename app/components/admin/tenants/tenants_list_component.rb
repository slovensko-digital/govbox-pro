class Admin::Tenants::TenantsListComponent < ViewComponent::Base
  def initialize(tenants)
    @tenants = tenants
  end
end
