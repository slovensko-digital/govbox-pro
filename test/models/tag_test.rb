require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "should mark tag readable by admin groups" do
    tenant = tenants(:ssd)
    tag = SimpleTag.create(name: 'New tag', tenant: tenant)

    assert tag.groups == [tenant.admin_group]
  end
end
