require "test_helper"

class MessageThreadTest < ActiveSupport::TestCase
  # find_or_create_by_merge_uuid!
  test "should create a new message thread if no merge_uuid match exists" do
    box = boxes(:ssd_main)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      folder: folders(:ssd_main_one),
      title: "Title",
      delivered_at: Time.current
    )

    assert_not_nil thread
  end

  test "should return existing thread if merge_uuid match exists" do
    box = boxes(:ssd_main)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_one_general).merge_identifiers.second.uuid,
      folder: folders(:ssd_main_one),
      title: "Title",
      delivered_at: Time.current
    )

    assert_equal message_threads(:ssd_main_one_general), thread
  end

  test "should update attributes when creating thread in wrong chronological order" do
    box = boxes(:ssd_main)
    older_delivered_at = message_threads(:ssd_main_one_general).delivered_at - 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_one_general).merge_identifiers.second.uuid,
      folder: folders(:ssd_main_two),
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal "New Title", thread.title
    assert_equal "New Title", thread.original_title
    assert_equal older_delivered_at, thread.delivered_at
    assert_equal folders(:ssd_main_two), thread.folder # yes, we WANT to update folder here
  end

  test "should update last_message_delivered_at attribute when new message in message thread" do
    box = boxes(:ssd_main)
    new_delivered_at = message_threads(:ssd_main_one_general).delivered_at + 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_one_general).merge_identifiers.second.uuid,
      folder: folders(:ssd_main_two),
      title: "New Title",
      delivered_at: new_delivered_at
    )

    assert_equal new_delivered_at, thread.last_message_delivered_at
  end

  test "should not update last_message_delivered_at attribute when creating thread in wrong chronological order" do
    box = boxes(:ssd_main)
    older_delivered_at = message_threads(:ssd_main_one_general).delivered_at - 1.day
    last_message_delivered_at = message_threads(:ssd_main_one_general).last_message_delivered_at

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_one_general).merge_identifiers.second.uuid,
      folder: folders(:ssd_main_one),
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal last_message_delivered_at, thread.last_message_delivered_at
  end

  test "should merge threads with correct last_message_delivered_at" do
    threads = folders(:ssd_main_one).message_threads
    target_last_message_delivered_at = message_threads(:ssd_main_one_delivery).last_message_delivered_at

    threads.merge_threads

    assert_equal threads.reload[0].last_message_delivered_at, target_last_message_delivered_at
  end

  test "should merge threads with correct delivered_at" do
    threads = folders(:ssd_main_one).message_threads
    target_delivered_at = message_threads(:ssd_main_one_general).delivered_at

    threads.merge_threads

    assert_equal threads.reload[0].delivered_at, target_delivered_at
  end

  test "should delete older thread during merge threads" do
    threads = folders(:ssd_main_one).message_threads

    threads.merge_threads

    assert_equal MessageThread.where(id: threads.map(&:id)).count, 1
  end

  test "should contain all messages in target thread after merge threads" do
    threads = MessageThread.where(id: [message_threads(:ssd_main_one_issue).id, message_threads(:ssd_main_one_general).id])

    threads.merge_threads

    new_main_thread_messages = threads.reload[0].messages

    assert_includes new_main_thread_messages, messages(:ssd_main_one_general_one)
    assert_includes new_main_thread_messages, messages(:ssd_main_one_general_two)
    assert_includes new_main_thread_messages, messages(:ssd_main_one_issue_one)
    assert_includes new_main_thread_messages, messages(:ssd_main_one_issue_two)
  end

  test "should not create tag thread relation across tenants" do
    tag = tags(:ssd_finance)
    thread = message_threads(:solver_main_one_general_agenda)

    thread.message_threads_tags.new(tag_id: tag.id)

    assert_raises(ActiveRecord::RecordInvalid) { thread.save! }
  end

  test 'should contain notes from all merged threads after merge' do
    threads = MessageThread.where(id: [message_threads(:ssd_main_one_issue).id, message_threads(:ssd_main_one_general).id])

    notes = threads.map(&:message_thread_note).map(&:note)

    assert_equal notes.length, 2

    threads.merge_threads

    merged_note = threads.reload[0].message_thread_note.note

    notes.each do |note|
      assert_match note, merged_note
    end
  end

  test "triggers callback event when new tags is assigned" do
    called = false
    EventBus.subscribe(:message_thread_tag_changed, ->(_message_thread_tag) {
      called = true
    })

    thread = message_threads(:ssd_main_one_general)
    thread.tags << tags(:ssd_print)

    # remove callback
    EventBus.class_variable_get(:@@subscribers_map)[:message_thread_tag_changed].pop

    assert called
  end
end
