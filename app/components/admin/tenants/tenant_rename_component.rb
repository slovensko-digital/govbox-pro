class Admin::Tenants::TenantRenameComponent < ViewComponent::Base
  def initialize(tenant)
    @tenant = tenant
  end
end
