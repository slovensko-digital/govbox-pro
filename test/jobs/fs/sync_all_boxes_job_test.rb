require "test_helper"

class Fs::SyncAllBoxesJobTest < ActiveJob::TestCase
  test "schedules one Fs::SyncApiConnectionJob per API connection with active syncable boxes" do
    Fs::SyncAllBoxesJob.perform_now

    enqueued_api_connection_jobs = enqueued_jobs_for(Fs::SyncApiConnectionJob)
    enqueued_box_jobs = enqueued_jobs_for(Fs::SyncBoxJob)
    expected_api_connections = Fs::ApiConnection.joins(:boxes).merge(Fs::Box.active.syncable).distinct

    assert_equal expected_api_connections.count, enqueued_api_connection_jobs.count
    assert_empty enqueued_box_jobs

    expected_api_connections.find_each do |api_connection|
      matching_jobs = enqueued_api_connection_jobs.count { |job| job_for_api_connection?(job, api_connection) }
      assert_equal 1, matching_jobs
    end
  end

  test "does not schedule api connection job for inactive boxes only" do
    inactive_box = boxes(:fs_accountants)
    active_box = boxes(:fs_accountants2)
    api_connection = api_connections(:fs_api_connection1)

    inactive_box.update!(active: false)
    active_box.update!(active: false)

    Fs::SyncAllBoxesJob.perform_now

    enqueued_api_connection_jobs = enqueued_jobs_for(Fs::SyncApiConnectionJob)
    assert enqueued_api_connection_jobs.none? { |job| job_for_api_connection?(job, api_connection) }
  end

  test "does not schedule api connection job for non-syncable boxes only" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.boxes.where(type: "Fs::Box").find_each { |box| box.update!(syncable: false) }

    Fs::SyncAllBoxesJob.perform_now

    enqueued_api_connection_jobs = enqueued_jobs_for(Fs::SyncApiConnectionJob)
    assert enqueued_api_connection_jobs.none? { |job| job_for_api_connection?(job, api_connection) }
  end

  test "does not schedule api connection job for inactive api connection assignments only" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.boxes_api_connections.find_each { |box_api_connection| box_api_connection.update!(active: false) }

    Fs::SyncAllBoxesJob.perform_now

    enqueued_api_connection_jobs = enqueued_jobs_for(Fs::SyncApiConnectionJob)
    assert enqueued_api_connection_jobs.none? { |job| job_for_api_connection?(job, api_connection) }
  end

  test "pings FS sync heartbeat" do
    BetterUptimeApi.stub :ping_heartbeat, ->(heartbeat) { @heartbeat = heartbeat } do
      Fs::SyncAllBoxesJob.perform_now
    end

    assert_equal "FS_SYNC", @heartbeat
  end

  private

  def enqueued_jobs_for(job_class)
    enqueued_jobs.select { |job| job[:job] == job_class }
  end

  def job_for_api_connection?(job, api_connection)
    job[:args].first["_aj_globalid"].include?(api_connection.id.to_s)
  end
end
