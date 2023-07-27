require "test_helper"

class MessageThreadTest < ActiveSupport::TestCase
  # find_or_create_by_merge_uuid!
  test "should create a new message thread if no merge_uuid match exists" do
    box = boxes(:one)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      folder: folders(:one),
      title: 'Title',
      delivered_at: Time.current,
    )

    assert_not_nil thread
  end

  test "should return existing thread if merge_uuid match exists" do
    box = boxes(:one)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_identifiers.second.uuid,
      folder: folders(:one),
      title: 'Title',
      delivered_at: Time.current,
    )

    assert_equal message_threads(:one), thread
  end

  test "should update attributes when creating thread in wrong chronological order" do
    box = boxes(:one)
    older_delivered_at = message_threads(:one).delivered_at - 1.day

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: message_threads(:one).merge_uuids.second,
      folder: folders(:two),
      title: 'New Title',
      delivered_at: older_delivered_at,
    )

    assert_equal 'New Title', thread.title
    assert_equal 'New Title', thread.original_title
    assert_equal older_delivered_at, thread.delivered_at
    assert_equal folders(:two), thread.folder # yes, we WANT to update folder here
  end
end
