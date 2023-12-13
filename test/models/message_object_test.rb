require "test_helper"

class MessageObjectTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:basic)
    @user_two = users(:basic_two)
    signers_group = groups(:ssd_signers)

    GroupMembership.create!(user: @user_one, group: signers_group)
    GroupMembership.create!(user: @user_two, group: signers_group)
  end

  test "add_signature_request_from_tag adds tag to the message_object and its thread along with general signature requests tag" do
    tenant = tenants(:ssd)
    object = message_objects(:ssd_main_general_one_attachment)

    assert_equal [], object.tags.reload
    assert_equal [], object.message.thread.tags.signing_tags.reload

    user_signature_requested_tag = @user_one.signature_requested_from_tag

    object.add_signature_request_from_tag(user_signature_requested_tag)
    assert_equal [user_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.tags.reload.to_set
    assert_equal [user_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set

    object.add_signature_request_from_tag(user_signature_requested_tag)
    assert_equal [user_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.tags.reload.to_set
    assert_equal [user_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set
  end

  test "add_signature_request_from_tag handles multiple signature tags properly" do
    tenant = tenants(:ssd)
    object = message_objects(:ssd_main_general_one_attachment)

    assert_equal [], object.tags.reload
    assert_equal [], object.message.thread.tags.signing_tags.reload

    user_1_signature_requested_tag = @user_one.signature_requested_from_tag

    object.add_signature_request_from_tag(user_1_signature_requested_tag)
    assert_equal [user_1_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set

    user_2_signature_requested_tag = @user_two.signature_requested_from_tag

    object.add_signature_request_from_tag(user_2_signature_requested_tag)
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set
  end

  test "remove_signature_request_from_tag removes user signature tag and general signature tag if there is no other users signature tag" do
    tenant = tenants(:ssd)
    object_1 = message_objects(:ssd_main_general_one_attachment)
    object_2 = message_objects(:ssd_main_general_two_from)

    user_1_signature_requested_tag = @user_one.signature_requested_from_tag
    user_2_signature_requested_tag = @user_two.signature_requested_from_tag

    object_1.add_signature_request_from_tag(user_1_signature_requested_tag)
    object_1.add_signature_request_from_tag(user_2_signature_requested_tag)
    object_2.add_signature_request_from_tag(user_1_signature_requested_tag)

    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_2.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.remove_signature_request_from_tag(user_1_signature_requested_tag)

    assert_equal [user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_2.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_2.remove_signature_request_from_tag(user_1_signature_requested_tag)

    assert_equal [user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.tags.reload.to_set
    assert_equal [], object_2.tags.reload
    assert_equal [user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.remove_signature_request_from_tag(user_2_signature_requested_tag)

    assert_equal [], object_1.tags.reload
    assert_equal [], object_2.tags.reload
    assert_equal [], object_1.message.thread.tags.signing_tags.reload
  end
end
