require "test_helper"

class GroupMembershipTest < ActiveSupport::TestCase
  test "creates signature tags for a user if a group is the signers group" do
    user = users(:basic)
    signers_group = groups(:ssd_signers)

    GroupMembership.create!(user: user, group: signers_group)

    user.reload
    assert user.signature_requested_from_tag
    assert_equal user.signature_requested_from_tag.groups, [user.user_group]
    assert user.signed_by_tag
    assert_equal user.signed_by_tag.groups, [user.user_group]
  end

  test "handles creation signature tags properly if some signing already exists" do
    tenant = tenants(:ssd)
    user = users(:basic)
    signers_group = groups(:ssd_signers)

    SignedByTag.create!(name: "something", groups: [user.user_group], tenant: tenant)
    SignatureRequestedFromTag.create!(name: "Na podpis - #{user.name}", tenant: tenant)

    GroupMembership.create!(user: user, group: signers_group)

    user.reload

    assert user.signature_requested_from_tag
    assert_equal user.signature_requested_from_tag.name, "Na podpis - Basic user"
    assert_equal user.signature_requested_from_tag.groups, [user.user_group]

    assert user.signed_by_tag
    assert_equal user.signed_by_tag.name, "Podpísané - Basic user"
    assert_equal user.signed_by_tag.groups, [user.user_group]
  end

  test "destroys signature_requested_from tags but keeps signed_by tags for a user if a group is the signers group" do
    user = users(:basic)
    signers_group = groups(:ssd_signers)

    membership = GroupMembership.create!(user: user, group: signers_group)
    membership.destroy

    user.reload

    assert_nil user.signature_requested_from_tag
    assert user.signed_by_tag
  end
end
