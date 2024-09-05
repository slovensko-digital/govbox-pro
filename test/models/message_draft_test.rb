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
      replyable: false
    )

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

    assert_enqueued_with(job: Govbox::SubmitMessageDraftJob, queue: :asap) do
      message_draft.submit(priority: :asap)
    end
  end
end
