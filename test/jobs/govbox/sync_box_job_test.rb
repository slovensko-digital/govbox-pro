require "test_helper"

class Govbox::SyncBoxJobTest < ActiveJob::TestCase
  test "schedules Govbox::SyncFolderJob with low priority if initial box sync" do
    box = boxes(:ssd_main)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_folders, [200, [
      {
        "id" => 123456,
        "name" => "Inbox",
        "system" => true
      },
      {
        "id" => 7890123,
        "name" => "MyName",
        "system" => false
      },
      {
        "id" => 135790,
        "name" => "Bin",
        "system" => true
      },
      {
        "id" => 24580,
        "name" => "Drafts",
        "system" => true
      },
      {
        "id" => 24589,
        "name" => "SentItems",
        "system" => true
      },
    ]]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      assert_enqueued_with(job: Govbox::SyncFolderJob, priority: 1000) do
        Govbox::SyncBoxJob.set(job_context: :later).perform_now(box)
      end
    end

    assert_enqueued_jobs 3
  end

  test "schedules Govbox::SyncFolderJob with no priority unless initial box sync" do
    box = boxes(:ssd_main)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_folders, [200, [
      {
        "id" => 123456,
        "name" => "Inbox",
        "system" => true
      },
      {
        "id" => 7890123,
        "name" => "MyName",
        "system" => false
      },
      {
        "id" => 135790,
        "name" => "Bin",
        "system" => true
      },
      {
        "id" => 24580,
        "name" => "Drafts",
        "system" => true
      },
      {
        "id" => 24589,
        "name" => "SentItems",
        "system" => true
      },
    ]]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      assert_enqueued_with(job: Govbox::SyncFolderJob, priority: nil) do
        Govbox::SyncBoxJob.perform_now(box)
      end
    end

    assert_enqueued_jobs 3
  end

  test "excludes selected folders from sync based on box settings" do
    box = boxes(:ssd_main)
    box.settings["sync_exclude_folder_ids"] = [7890124, 7890125, 7890127]
    box.save!

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_folders, [200, [
      {
        "id" => 123456,
        "name" => "Inbox",
        "system" => true
      },
      {
        "id" => 7890123,
        "name" => "Folder A",
        "system" => false
      },
      {
        "id" => 7890124,
        "name" => "Legacy Folder B",
        "system" => false
      },
      {
        "id" => 7890125,
        "name" => "Legacy Folder C",
        "system" => false
      },
      {
        "id" => 7890126,
        "name" => "Folder D",
        "system" => false
      },
      {
        "id" => 7890127,
        "name" => "Legacy Folder E",
        "system" => false
      },
      {
        "id" => 135790,
        "name" => "Bin",
        "system" => true
      },
      {
        "id" => 24580,
        "name" => "Drafts",
        "system" => true
      },
      {
        "id" => 24589,
        "name" => "SentItems",
        "system" => true
      },
    ]]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      Govbox::SyncBoxJob.perform_now(box)
    end

    assert_enqueued_jobs 4
  end
end
