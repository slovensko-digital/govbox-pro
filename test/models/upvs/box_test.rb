require "test_helper"

class Upvs::BoxTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "sync method schedules Govbox::SyncBoxJob with highest priority" do
    box = boxes(:ssd_main)

    assert_enqueued_with(job: Govbox::SyncBoxJob, priority: -1000) do
      box.sync
    end
  end

  test "sync_all schedules sync of all boxes with selected API connections" do
    assert_enqueued_with(job: Govbox::SyncBoxJob) do
      Upvs::Box.sync_all
    end

    assert_enqueued_jobs Upvs::Box.where(syncable: true).count
  end
end
