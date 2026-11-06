require "test_helper"
require "helpers/good_job_helper"

class ReindexAndNotifyFilterSubscriptionsJobTest < ActiveJob::TestCase
  include GoodJobHelper

  test "perform_later_for_tag_id labels the jobs with the thread id" do
    # The label is resolved again when the job is performed, so it must not
    # depend on the identity of the argument objects.
    thread = message_threads(:ssd_main_general)
    Searchable::Indexer.index_message_thread(thread)

    ReindexAndNotifyFilterSubscriptionsJob.perform_later_for_tag_id(thread.tags.first.id)

    assert_equal ["ReindexAndNotifyFilterSubscriptionsJob-#{thread.id}"], GoodJob::Job.sole.labels
  end
end
