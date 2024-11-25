# == Schema Information
#
# Table name: message_threads
#
#  id                        :bigint           not null, primary key
#  delivered_at              :datetime         not null
#  last_message_delivered_at :datetime         not null
#  original_title            :string           not null
#  title                     :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  box_id                    :bigint           not null
#  folder_id                 :bigint
#
require "test_helper"

class MessageThreadTest < ActiveSupport::TestCase
  # find_or_create_by_merge_uuid!
  test "should create a new message thread if no merge_uuid match exists" do
    box = boxes(:ssd_main)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      box: box,
      title: "Title",
      delivered_at: Time.current
    )

    assert_not_nil thread
  end

  test "should return existing thread if merge_uuid match exists" do
    box = boxes(:ssd_main)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_general).merge_identifiers.second.uuid,
      box: box,
      title: "Title",
      delivered_at: Time.current
    )

    assert_equal message_threads(:ssd_main_general), thread
  end

  test "should update attributes when creating thread in wrong chronological order" do
    box = boxes(:ssd_main)
    older_delivered_at = message_threads(:ssd_main_general).delivered_at - 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_general).merge_identifiers.second.uuid,
      box: box,
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal "New Title", thread.title
    assert_equal "New Title", thread.original_title
    assert_equal older_delivered_at, thread.delivered_at
  end

  test "should update last_message_delivered_at attribute when new message in message thread" do
    box = boxes(:ssd_main)
    new_delivered_at = message_threads(:ssd_main_general).delivered_at + 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_general).merge_identifiers.second.uuid,
      box: box,
      title: "New Title",
      delivered_at: new_delivered_at
    )

    assert_equal new_delivered_at, thread.last_message_delivered_at
  end

  test "should not update last_message_delivered_at attribute when creating thread in wrong chronological order" do
    box = boxes(:ssd_main)
    older_delivered_at = message_threads(:ssd_main_general).delivered_at - 1.day
    last_message_delivered_at = message_threads(:ssd_main_general).last_message_delivered_at

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:ssd_main_general).merge_identifiers.second.uuid,
      box: box,
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal last_message_delivered_at, thread.last_message_delivered_at
  end

  test "should not merge threads from different boxes" do
    thread1 = message_threads(:ssd_main_general)
    thread2 = message_threads(:solver_main_delivery_notification)
    threads = MessageThread.where(id: [thread1.id, thread2.id])

    message_from_thread1 = thread1.messages.first
    message_from_thread2 = thread2.messages.first

    threads.merge_threads

    assert_not_equal message_from_thread1.reload.thread, message_from_thread2.reload.thread
  end

  test "should merge threads with correct last_message_delivered_at" do
    threads = boxes(:ssd_main).message_threads
    target_last_message_delivered_at = message_threads(:ssd_main_delivery).last_message_delivered_at

    threads.merge_threads

    assert_equal threads.reload[0].last_message_delivered_at, target_last_message_delivered_at
  end

  test "should merge threads with correct delivered_at" do
    threads = boxes(:ssd_main).message_threads
    target_delivered_at = message_threads(:ssd_main_general).delivered_at

    threads.merge_threads

    assert_equal threads.reload[0].delivered_at, target_delivered_at
  end

  test "should delete older thread during merge threads" do
    threads = boxes(:ssd_main).message_threads

    threads.merge_threads

    assert_equal MessageThread.where(id: threads.map(&:id)).count, 1
  end

  test "should contain all messages in target thread after merge threads" do
    threads = MessageThread.where(id: [message_threads(:ssd_main_issue).id, message_threads(:ssd_main_general).id])

    threads.merge_threads

    new_main_thread_messages = threads.reload[0].messages

    assert_includes new_main_thread_messages, messages(:ssd_main_general_one)
    assert_includes new_main_thread_messages, messages(:ssd_main_general_two)
    assert_includes new_main_thread_messages, messages(:ssd_main_issue_one)
    assert_includes new_main_thread_messages, messages(:ssd_main_issue_two)
  end

  test "should not create tag thread relation across tenants" do
    tag = tags(:ssd_finance)
    thread = message_threads(:solver_main_general_agenda)

    thread.message_threads_tags.new(tag_id: tag.id)

    assert_raises(ActiveRecord::RecordInvalid) { thread.save! }
  end

  test 'should contain notes from all merged threads after merge' do
    threads = MessageThread.where(id: [message_threads(:ssd_main_issue).id, message_threads(:ssd_main_general).id])

    notes = threads.map(&:message_thread_note).map(&:note)

    assert_equal notes.length, 2

    threads.merge_threads

    merged_note = threads.reload[0].message_thread_note.note

    notes.each do |note|
      assert_match note, merged_note
    end
  end

  test "triggers callback event when new tags is assigned" do
    thread = message_threads(:ssd_main_general)

    subscriber1 = Minitest::Mock.new
    subscriber1.expect :call, true, [MessageThreadsTag]

    EventBus.subscribe(:message_thread_tag_changed, subscriber1)

    thread.tags << tags(:ssd_print)

    assert_mock subscriber1

    # remove callback
    EventBus.class_variable_get(:@@subscribers_map)[:message_thread_tag_changed].pop
  end
end
