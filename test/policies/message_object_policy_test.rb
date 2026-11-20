require 'test_helper'

class MessageObjectPolicyTest < ActiveSupport::TestCase
  def setup
    @form_object = message_objects(:fs_accountants_draft_uzmujv14_form2)
    @owner = users(:accountants_user2)
    @owner.groups << @owner.tenant.signer_group
    api_connections(:fs_api_connection1).update!(owner: @owner)
  end

  test 'update? returns false for a signer who can not sign the Fs::MessageDraft' do
    signer = users(:accountants_basic)
    signer.groups << signer.tenant.signer_group

    assert_not MessageObjectPolicy.new(signer, @form_object).update?
  end

  test 'update? returns true for a signer who owns the only api connection of the box' do
    assert MessageObjectPolicy.new(@owner, @form_object).update?
  end
end
