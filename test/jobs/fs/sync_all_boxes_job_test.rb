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

  private

  def enqueued_jobs_for(job_class)
    enqueued_jobs.select { |job| job[:job] == job_class }
  end
end
