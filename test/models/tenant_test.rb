require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "all system tags and groups are created with tenant" do
    tenant = Tenant.create!(name: "new one")

    assert tenant.all_group
    assert tenant.signer_group
    assert tenant.admin_group
    assert tenant.draft_tag
    assert tenant.everything_tag
    assert tenant.signature_requested_tag
    assert tenant.signed_tag
    assert tenant.signed_externally_tag
    assert_equal tenant.everything_tag.groups, [tenant.admin_group]
  end
end
