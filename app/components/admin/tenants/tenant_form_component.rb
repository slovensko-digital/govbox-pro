class Admin::Tenants::TenantFormComponent < ViewComponent::Base
  def initialize(tenant:, action:)
    @tenant = tenant
    @action = action
  end
end
