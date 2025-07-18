require "test_helper"

class MessageDraftTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "created! method publishes events on EventBus" do
    box = boxes(:ssd_main)
    message = MessageDraft.create(
      uuid: SecureRandom.uuid,
      title: 'message title',
      sender_name: 'social department',
      recipient_name: box.name,
      delivered_at: Time.now,
      thread: box.message_threads.first,
      read: true,
      replyable: false,
      metadata: {
        correlation_id: SecureRandom.uuid
      }
    )

    skip("TODO EventBus fix")

    subscriber1 = Minitest::Mock.new
    subscriber1.expect :call, true, [message]

    subscriber2 = Minitest::Mock.new
    subscriber2.expect :perform_later, true, [:message_thread_created, message.thread]

    EventBus.subscribe(:message_created, subscriber1)
    EventBus.subscribe_job(:message_thread_created, subscriber2)

    message.created!

    assert_mock subscriber1
    assert_mock subscriber2

    # remove callbacks
    EventBus.class_variable_get(:@@subscribers_map)[:message_created].pop
    EventBus.class_variable_get(:@@subscribers_map)[:message_thread_created].pop
  end

  test ".find_api_connection_for_submission finds API connection according to signatures" do
    message_draft = messages(:fs_accountants_draft)

    user1 = users(:accountants_basic)
    user1_api_connection = user1.tenant.api_connections.find_by(owner: user1)
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user1))

    assert_equal user1_api_connection, message_draft.find_api_connection_for_submission

    user2 = users(:accountants_user2)
    user2_api_connection = user2.tenant.api_connections.find_by(owner: user2)
    message_draft.thread.unassign_tag(SignedByTag.find_by(owner: user1))
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user2))

    assert_equal user2_api_connection, message_draft.find_api_connection_for_submission

    user3 = users(:accountants_user2)
    user3_api_connection = user3.tenant.api_connections.find_by(owner: user3)
    message_draft.thread.unassign_tag(SignedByTag.find_by(owner: user2))
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user3))

    assert_equal user3_api_connection, message_draft.find_api_connection_for_submission
  end

  test ".find_api_connection_for_submission raises if messages is signed by multiple users" do
    message_draft = messages(:fs_accountants_draft)

    user1 = users(:accountants_basic)
    user2 = users(:accountants_user2)
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user1))
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user2))

    assert_raises(RuntimeError) do
      message_draft.find_api_connection_for_submission
    end
  end

  test ".find_api_connection_for_submission raises if messages is signed by another user (with no api connection for the box)" do
    box = boxes(:fs_accountants_multiple_api_connections)
    message_draft = messages(:fs_accountants_draft)

    box.other_api_connections.delete(api_connections(:fs_api_connection6))

    user = users(:accountants_user3)
    message_draft.thread.assign_tag(SignedByTag.find_by(owner: user))

    assert_raises(RuntimeError) do
      message_draft.find_api_connection_for_submission
    end
  end

  test 'being_submitted! method adds SubmittedTag' do
    message_draft = messages(:ssd_main_delivery_draft)

    message_draft.being_submitted!

    message_thread = message_draft.thread
    submitted_tag = message_thread.tags.find_by(type: SubmittedTag.to_s)

    assert message_thread.tags.reload.include?(submitted_tag)
  end

  test 'being_submitted! removes DraftTag if no more drafts not in submission process present' do
    message_draft = messages(:ssd_main_delivery_draft)

    message_draft.being_submitted!

    message_thread = message_draft.thread
    draft_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    assert_not message_thread.tags.reload.include?(draft_tag)
  end

  test 'being_submitted! keeps DraftTag if drafts not in submission process present' do
    message_draft = messages(:ssd_main_delivery_draft)

    message_draft2 = message_draft.dup
    message_draft2.update(uuid: SecureRandom.uuid)
    message_draft2.save

    message_draft.being_submitted!

    message_thread = message_draft.thread
    draft_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    assert message_thread.tags.reload.include?(draft_tag)
  end

  test 'after destroy callback should keep message thread drafts tag if message drafts present' do
    message_draft = messages(:ssd_main_general_draft_one)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread
    drafts_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    message_draft.destroy

    assert message_thread.tags.include?(drafts_tag)
  end

  test 'after destroy callback should delete message thread drafts tag if no message drafts left' do
    message_draft = messages(:ssd_main_delivery_draft)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread
    drafts_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    message_draft.destroy

    assert_not message_thread.tags.reload.include?(drafts_tag)
  end

  test 'after destroy callback should delete message thread SubmittedTag if no message drafts in submission process left' do
    message_draft = messages(:ssd_main_delivery_draft)
    message_draft.being_submitted!

    message_thread = message_draft.thread
    submitted_tag = message_thread.tags.find_by(type: SubmittedTag.to_s)

    message_draft.destroy

    assert_not message_thread.tags.reload.include?(submitted_tag)
  end

  test 'after destroy callback should keep message thread SubmittedTag if message drafts in submission process present' do
    message_draft = messages(:ssd_main_delivery_draft)
    message_draft.being_submitted!

    message_draft2 = message_draft.dup
    message_draft2.update(uuid: SecureRandom.uuid)
    message_draft2.save

    message_thread = message_draft.thread
    submitted_tag = message_thread.tags.find_by(type: SubmittedTag.to_s)

    message_draft.destroy

    assert message_thread.tags.reload.include?(submitted_tag)
  end

  test 'after destroy callback should destroy message thread if no messages left' do
    message_draft = messages(:ssd_main_draft)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread

    message_draft.destroy

    assert message_thread.destroyed?
  end

  test "single draft submission schedules jobs with highest priority" do
    message_draft = messages(:ssd_main_draft)

    assert_enqueued_with(job: Govbox::SubmitMessageDraftJob, priority: -1000) do
      message_draft.submit
    end
  end
end
