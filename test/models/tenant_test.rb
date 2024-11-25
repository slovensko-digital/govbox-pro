# == Schema Information
#
# Table name: tenants
#
#  id                   :bigint           not null, primary key
#  api_token_public_key :string
#  feature_flags        :string           default([]), is an Array
#  name                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "all system tags and groups are created with tenant" do
    tenant = Tenant.create!(name: "new one")

    assert tenant.all_group
    assert tenant.signer_group
    assert tenant.admin_group
    assert tenant.draft_tag
    assert tenant.everything_tag
    assert tenant.archived_tag
    assert tenant.signature_requested_tag
    assert tenant.signed_tag
    assert tenant.signed_externally_tag
    assert_equal tenant.everything_tag.groups, [tenant.admin_group]
  end
end
