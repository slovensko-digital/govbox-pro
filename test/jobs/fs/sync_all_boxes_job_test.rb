require "test_helper"

class Fs::SyncAllBoxesJobTest < ActiveJob::TestCase
  test "schedules Fs::SyncBoxJob with API connections selected according to unique delegate_id value" do
    accountants_box = boxes(:fs_accountants)
    delegate_box = boxes(:fs_delegate)
    box_with_three_different_connections = boxes(:fs_accountants_multiple_api_connections)

    assert_enqueued_jobs 0

    Fs::SyncAllBoxesJob.perform_now

    enqueued_jobs = enqueued_jobs_for(Fs::SyncBoxJob)

    accountants_box_sync_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(accountants_box.id.to_s) }
    assert_equal 1, accountants_box_sync_jobs.count
    assert accountants_box_sync_jobs.first[:args].second["api_connection"]["_aj_globalid"].include?(accountants_box.api_connection.id.to_s)

    delegate_box_sync_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(delegate_box.id.to_s) }
    assert_equal 1, delegate_box_sync_jobs.count
    assert delegate_box_sync_jobs.first[:args].second["api_connection"]["_aj_globalid"].include?(delegate_box.api_connection.id.to_s)

    box_with_multiple_connections_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(box_with_three_different_connections.id.to_s) }
    assert_equal 3, box_with_multiple_connections_jobs.count
    box_with_three_different_connections.boxes_api_connections.find_each do |box_api_connection|
      assert_equal 1, box_with_multiple_connections_jobs.select { |job| job[:args].second["api_connection"]["_aj_globalid"].include?(box_api_connection.api_connection.id.to_s) }.count
    end
  end

  test "does not schedule sync for inactive boxes" do
    inactive_box = boxes(:fs_accountants)
    inactive_box.update!(active: false)

    Fs::SyncAllBoxesJob.perform_now

    enqueued_jobs = enqueued_jobs_for(Fs::SyncBoxJob)
    inactive_box_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(inactive_box.id.to_s) }

    assert_equal 0, inactive_box_jobs.count
  end

  test "schedules sync only for active boxes when mixed" do
    active_box = boxes(:fs_delegate)
    inactive_box = boxes(:fs_accountants)
    inactive_box.update!(active: false)

    Fs::SyncAllBoxesJob.perform_now

    enqueued_jobs = enqueued_jobs_for(Fs::SyncBoxJob)
    active_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(active_box.id.to_s) }
    inactive_jobs = enqueued_jobs.select { |job| job[:args].first["_aj_globalid"].include?(inactive_box.id.to_s) }

    assert active_jobs.any?
    assert_equal 0, inactive_jobs.count
  end

  private

  def enqueued_jobs_for(job_class)
    enqueued_jobs.select { |job| job[:job] == job_class }
  end
end
