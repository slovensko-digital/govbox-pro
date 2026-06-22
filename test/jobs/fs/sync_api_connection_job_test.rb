require "test_helper"

class Fs::SyncApiConnectionJobTest < ActiveJob::TestCase
  setup do
    clear_enqueued_jobs
  end

  test "syncs first eligible box inline and enqueues remaining boxes after success" do
    api_connection = api_connections(:fs_api_connection1)
    boxes = eligible_boxes(api_connection).to_a
    assert_operator boxes.size, :>=, 2

    fs_api = Minitest::Mock.new
    fs_api.expect :fetch_received_messages, { "messages" => [] }, page: 1, count: 25, from: Date.yesterday, to: Date.tomorrow
    fs_api.expect :obo_without_delegate, nil
    fs_api.expect :fetch_received_messages, { "messages" => [] }, page: 1, count: 25, from: Date.yesterday, to: Date.tomorrow, obo: nil

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, api_connection: api_connection, box: boxes.first

    assert_enqueued_jobs boxes.size - 1, only: Fs::SyncBoxJob do
      FsEnvironment.stub :fs_client, fs_client do
        Fs::SyncApiConnectionJob.perform_now(api_connection)
      end
    end

    enqueued_sync_box_jobs = enqueued_jobs_for(Fs::SyncBoxJob)
    assert_not_enqueued_for_box(enqueued_sync_box_jobs, boxes.first)
    boxes.drop(1).each { |box| assert_enqueued_for_box(enqueued_sync_box_jobs, box) }

    fs_api.verify
    fs_client.verify
  end

  test "does not enqueue remaining boxes after authentication failure on first box" do
    api_connection = api_connections(:fs_api_connection1)
    first_box = eligible_boxes(api_connection).first

    expected_api_connection = api_connection
    fs_client = Class.new do
      define_method(:api) do |api_connection:, box:|
        raise "unexpected api connection" unless api_connection == expected_api_connection
        raise "unexpected box" unless box == first_box

        Class.new do
          def fetch_received_messages(**)
            raise Fs::AuthenticationError, "bad credentials"
          end
        end.new
      end
    end.new

    FsEnvironment.stub :fs_client, fs_client do
      Fs::SyncApiConnectionJob.perform_now(api_connection)
    end

    assert_no_enqueued_jobs only: Fs::SyncBoxJob
    assert api_connection.reload.authentication_failed?
  end

  test "does not enqueue remaining sync boxes after non-authentication errors" do
    api_connection = api_connections(:fs_api_connection1)
    first_box = eligible_boxes(api_connection).first

    fs_api = Minitest::Mock.new
    fs_api.expect :fetch_received_messages, nil do |**|
      raise StandardError, "temporary outage"
    end

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, api_connection: api_connection, box: first_box

    FsEnvironment.stub :fs_client, fs_client do
      Fs::SyncApiConnectionJob.perform_now(api_connection)
    end

    assert_no_enqueued_jobs only: Fs::SyncBoxJob
    assert_enqueued_jobs 1, only: Fs::SyncApiConnectionJob
  end

  test "skips inactive and non-syncable boxes" do
    api_connection = api_connections(:fs_api_connection1)
    first_box, second_box = api_connection.boxes.where(type: "Fs::Box").order(:id).to_a
    first_box.update!(active: false)
    second_box.update!(syncable: false)

    Fs::SyncApiConnectionJob.perform_now(api_connection)

    assert_no_enqueued_jobs only: Fs::SyncBoxJob
  end

  test "skips boxes with inactive api connection assignment" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.boxes_api_connections.find_each { |box_api_connection| box_api_connection.update!(active: false) }

    Fs::SyncApiConnectionJob.perform_now(api_connection)

    assert_no_enqueued_jobs only: Fs::SyncBoxJob
  end

  test "handles api connection with no eligible boxes" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.boxes.where(type: "Fs::Box").find_each { |box| box.update!(active: false) }

    Fs::SyncApiConnectionJob.perform_now(api_connection)

    assert_no_enqueued_jobs only: Fs::SyncBoxJob
  end

  private

  def eligible_boxes(api_connection)
    api_connection.boxes.where(type: "Fs::Box").active.syncable.order(:id)
  end

  def enqueued_jobs_for(job_class)
    enqueued_jobs.select { |job| job[:job] == job_class }
  end

  def assert_enqueued_for_box(jobs, box)
    assert jobs.any? { |job| job_for_box?(job, box) }
  end

  def assert_not_enqueued_for_box(jobs, box)
    assert jobs.none? { |job| job_for_box?(job, box) }
  end

  def job_for_box?(job, box)
    job[:args].first["_aj_globalid"].include?(box.id.to_s)
  end
end
