require "test_helper"

class Searchable::ReindexMessageThreadJobTest < ActiveJob::TestCase
  test "reindexes thread by id" do
    thread_one = message_threads(:one)
    Searchable::ReindexMessageThreadJob.new.perform(thread_one.id)

    Searchable::MessageThread.find_by_message_thread_id!(thread_one.id)
  end

  test "ignores invalid id" do
    thread_one = message_threads(:one)
    invalid_id = thread_one.id + 1_000

    assert_nothing_raised do
      Searchable::ReindexMessageThreadJob.new.perform(invalid_id)
    end

    assert_nil Searchable::MessageThread.find_by_message_thread_id(invalid_id)
  end
end
