require "test_helper"

class GroupMembershipTest < ActiveSupport::TestCase
  test 'after create callback creates signature tags for a user if the user is added to the signers group' do
    user = users(:basic)
    signers_group = groups(:ssd_signers)

    GroupMembership.create!(user: user, group: signers_group)

    user.reload
    assert user.signature_requested_to_tag
    assert user.signed_by_tag
  end
end
