require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "should mark tag readable by admin groups" do
    tenant = tenants(:solver)
    tag = Tag.create(system_name: 'New tag', name: 'New tag', tenant: tenant)

    assert tenant.admin_groups == tag.groups
  end
end
