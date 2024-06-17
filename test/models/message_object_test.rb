require "test_helper"

class MessageObjectTest < ActiveSupport::TestCase
  setup do
    @user_one = users(:basic)
    @user_two = users(:basic_two)
    signers_group = groups(:ssd_signers)

    GroupMembership.create!(user: @user_one, group: signers_group)
    GroupMembership.create!(user: @user_two, group: signers_group)
  end

  test "add_signature_requested_from_user adds tag to the message_object and its thread along with general signature requests tag" do
    tenant = tenants(:ssd)
    object = message_objects(:ssd_main_general_one_attachment)

    assert_equal [], object.tags.reload
    assert_equal [], object.message.thread.tags.signing_tags.reload

    object.add_signature_requested_from_user(@user_one)
    assert_equal [@user_one.signature_requested_from_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set

    object.add_signature_requested_from_user(@user_one)
    assert_equal [@user_one.signature_requested_from_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set
  end

  test "add_signature_requested_from_user handles multiple signature tags properly" do
    tenant = tenants(:ssd)
    object = message_objects(:ssd_main_general_one_attachment)

    assert_equal [], object.tags.reload
    assert_equal [], object.message.thread.tags.signing_tags.reload

    object.add_signature_requested_from_user(@user_one)
    assert_equal [@user_one.signature_requested_from_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set

    object.add_signature_requested_from_user(@user_two)
    assert_equal [@user_one.signature_requested_from_tag, @user_two.signature_requested_from_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, @user_two.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set
  end

  test "add_signature_requested_from_user does nothing when requested user has already signed the object" do
    tenant = tenants(:ssd)
    object = message_objects(:ssd_main_general_one_attachment)

    object.mark_signed_by_user(@user_one)

    assert_equal [@user_one.signed_by_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, tenant.signed_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set

    object.add_signature_requested_from_user(@user_one)

    assert_equal [@user_one.signed_by_tag].to_set,
                 object.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, tenant.signed_tag!].to_set,
                 object.message.thread.tags.signing_tags.reload.to_set
  end

  test "remove_signature_requested_from_user removes user signature tag and tenant signature tag if there is no other users signature tag" do
    tenant = tenants(:ssd)
    object_1 = message_objects(:ssd_main_general_one_attachment)
    object_2 = message_objects(:ssd_main_general_two_form)

    user_1_signature_requested_tag = @user_one.signature_requested_from_tag
    user_2_signature_requested_tag = @user_two.signature_requested_from_tag

    object_1.add_signature_requested_from_user(@user_one)
    object_1.add_signature_requested_from_user(@user_two)
    object_2.add_signature_requested_from_user(@user_one)

    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.remove_signature_requested_from_user(@user_one)

    assert_equal [user_2_signature_requested_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [user_1_signature_requested_tag, user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_2.remove_signature_requested_from_user(@user_one)

    assert_equal [user_2_signature_requested_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [], object_2.tags.reload
    assert_equal [user_2_signature_requested_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.remove_signature_requested_from_user(@user_two)

    assert_equal [], object_1.tags.reload
    assert_equal [], object_2.tags.reload
    assert_equal [], object_1.message.thread.tags.signing_tags.reload
  end

  test "mark_signed_by_user removes user_signature_requested_tags and mark object and thread as signed if there is not other signature requested tag" do
    tenant = tenants(:ssd)
    object_1 = message_objects(:ssd_main_general_one_attachment)
    object_2 = message_objects(:ssd_main_general_two_form)

    object_1.add_signature_requested_from_user(@user_one)
    object_1.add_signature_requested_from_user(@user_two)
    object_2.add_signature_requested_from_user(@user_one)

    assert_equal [@user_one.signature_requested_from_tag, @user_two.signature_requested_from_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, @user_two.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.mark_signed_by_user(@user_one)

    assert_equal [@user_one.signed_by_tag, @user_two.signature_requested_from_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signature_requested_from_tag, @user_two.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_2.mark_signed_by_user(@user_one)

    assert_equal [@user_one.signed_by_tag, @user_two.signature_requested_from_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, @user_two.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.mark_signed_by_user(@user_two)

    assert_equal [@user_one.signed_by_tag, @user_two.signed_by_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, @user_two.signed_by_tag, tenant.signed_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set
  end

  test "signature_requested_from is added and removed to fully signed thread" do
    tenant = tenants(:ssd)
    object_1 = message_objects(:ssd_main_general_one_attachment)
    object_2 = message_objects(:ssd_main_general_two_form)

    object_1.mark_signed_by_user(@user_one)
    object_2.mark_signed_by_user(@user_two)

    assert_equal [@user_one.signed_by_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_two.signed_by_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, @user_two.signed_by_tag, tenant.signed_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.add_signature_requested_from_user(@user_two)
    assert_equal [@user_one.signed_by_tag, @user_two.signature_requested_from_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_two.signed_by_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, @user_two.signature_requested_from_tag, tenant.signature_requested_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set

    object_1.remove_signature_requested_from_user(@user_two)
    assert_equal [@user_one.signed_by_tag].to_set,
                 object_1.tags.reload.to_set
    assert_equal [@user_two.signed_by_tag].to_set,
                 object_2.tags.reload.to_set
    assert_equal [@user_one.signed_by_tag, @user_two.signed_by_tag, tenant.signed_tag!].to_set,
                 object_1.message.thread.tags.signing_tags.reload.to_set
  end

  test "before_destroy callback deletes object related tags from message thread after object removal (if no more objects with the tag present)" do
    tenant = tenants(:ssd)
    signer = users(:basic_two)
    signed_by_tag = tags(:ssd_basic_user_signed)

    object = message_objects(:ssd_main_general_one_attachment)
    object.mark_signed_by_user(signer)

    assert object.tags.include?(signed_by_tag)
    assert object.message.thread.tags.include?(signed_by_tag)
    assert object.message.thread.tags.include?(tenant.signed_tag!)

    object.destroy

    assert_not object.message.thread.tags.reload.include?(signed_by_tag)
    assert_not object.message.thread.tags.include?(tenant.signed_tag!)
  end

  test "before_destroy callback keeps object related tags for message thread after object removal (if another objects with the tag present in the message)" do
    tenant = tenants(:ssd)
    signer = users(:basic_two)
    signed_by_tag = tags(:ssd_basic_user_signed)

    attachment_object = message_objects(:ssd_main_general_draft_one_attachment)
    attachment_object.mark_signed_by_user(signer)

    assert attachment_object.tags.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(tenant.signed_tag!)

    form_object = attachment_object.message.form_object
    form_object.mark_signed_by_user(signer)

    assert form_object.tags.include?(signed_by_tag)
    assert form_object.message.thread.tags.include?(signed_by_tag)

    attachment_object.destroy

    assert attachment_object.message.thread.tags.reload.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(tenant.signed_tag!)
  end

  test "before_destroy callback keeps object related tags for message thread after object removal (if objects with the tag present in another message in the thread)" do
    tenant = tenants(:ssd)
    signer = users(:basic_two)
    signed_by_tag = tags(:ssd_basic_user_signed)

    attachment_object = message_objects(:ssd_main_general_one_attachment)
    attachment_object.mark_signed_by_user(signer)

    assert attachment_object.tags.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(tenant.signed_tag!)

    form_object = message_objects(:ssd_main_general_draft_two_form)
    form_object.mark_signed_by_user(signer)

    assert form_object.tags.include?(signed_by_tag)
    assert form_object.message.thread.tags.include?(signed_by_tag)

    attachment_object.destroy

    assert attachment_object.message.thread.tags.reload.include?(signed_by_tag)
    assert attachment_object.message.thread.tags.include?(tenant.signed_tag!)
  end

  test "prepares PDF visualization" do
    message_object = message_objects(:ssd_main_fs_one_form)

    skip('Test needs to be run in docker')

    assert_not_equal nil, message_object.prepare_pdf_visualization
  end
end
