require "test_helper"

class MessageThreadTest < ActiveSupport::TestCase
  # find_or_create_by_merge_uuid!
  test "should create a new message thread if no merge_uuid match exists" do
    box = boxes(:one)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      folder: folders(:one),
      title: "Title",
      delivered_at: Time.current
    )

    assert_not_nil thread
  end

  test "should return existing thread if merge_uuid match exists" do
    box = boxes(:one)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_identifiers.second.uuid,
      folder: folders(:one),
      title: "Title",
      delivered_at: Time.current
    )

    assert_equal message_threads(:one), thread
  end

  test "should update attributes when creating thread in wrong chronological order" do
    box = boxes(:one)
    older_delivered_at = message_threads(:one).delivered_at - 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_identifiers.second.uuid,
      folder: folders(:three),
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal "New Title", thread.title
    assert_equal "New Title", thread.original_title
    assert_equal older_delivered_at, thread.delivered_at
    assert_equal folders(:three), thread.folder # yes, we WANT to update folder here
  end

  test "should update last_message_delivered_at attribute when new message in message thread" do
    box = boxes(:one)
    new_delivered_at = message_threads(:one).delivered_at + 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_identifiers.second.uuid,
      folder: folders(:three),
      title: "New Title",
      delivered_at: new_delivered_at
    )

    assert_equal new_delivered_at, thread.last_message_delivered_at
  end

  test "should not update last_message_delivered_at attribute when creating thread in wrong chronological order" do
    box = boxes(:one)
    older_delivered_at = message_threads(:one).delivered_at - 1.day
    last_message_delivered_at = message_threads(:one).last_message_delivered_at

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_identifiers.second.uuid,
      folder: folders(:three),
      title: "New Title",
      delivered_at: older_delivered_at
    )

    assert_equal last_message_delivered_at, thread.last_message_delivered_at
  end

  test "should merge threads with correct last_message_delivered_at" do
    threads = MessageThread.all
    target_last_message_delivered_at = message_threads(:two).last_message_delivered_at

    threads.merge_threads

    assert_equal target_last_message_delivered_at, message_threads(:two).last_message_delivered_at
  end

  test "should merge threads with correct delivered_at" do
    threads = MessageThread.all
    target_delivered_at = message_threads(:one).last_message_delivered_at

    threads.merge_threads

    assert_equal target_delivered_at, message_threads(:one).delivered_at
  end

  test "should delete older thread during merge threads" do
    threads = MessageThread.all

    threads.merge_threads

    assert_raises(ActiveRecord::RecordNotFound) { message_threads(:one) }
  end

  test "should contain all messages in target thread after merge threads" do
    threads = MessageThread.where(id: [message_threads(:two).id, message_threads(:one).id])

    threads.merge_threads

    assert_includes message_threads(:two).messages, messages(:one)
    assert_includes message_threads(:two).messages, messages(:two)
    assert_includes message_threads(:two).messages, messages(:three)
    assert_includes message_threads(:two).messages, messages(:four)
  end

  test "should not create tag thread relation across tenants" do
    tag = tags(:one)
    thread = message_threads(:four)

    thread.message_threads_tags.new(tag_id: tag.id)

    assert_raises(ActiveRecord::RecordInvalid) { thread.save! }
  end

  test 'should contain notes from both merged threads after merge' do
    threads = MessageThread.where(id: [message_threads(:two).id, message_threads(:one).id])

    threads.merge_threads

    assert_match 'Note1', message_threads(:two).message_thread_note.note
    assert_match 'Note2', message_threads(:two).message_thread_note.note
  end

  test "triggers callback event when new tags is assigned" do
    called = false
    EventBus.subscribe(:message_thread_tag_changed, ->(_message_thread_tag) {
      called = true
    })

    thread = message_threads(:one)
    thread.tags << tags(:one)

    # remove callback
    EventBus.class_variable_get(:@@subscribers_map)[:message_thread_tag_changed].pop

    assert called
  end
end
