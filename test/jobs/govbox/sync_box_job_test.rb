require "test_helper"

class Govbox::SyncBoxJobTest < ActiveJob::TestCase
  test "schedules Govbox::SyncFolderJob with low priority if initial box sync" do
    box = boxes(:ssd_main)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_folders, [200, [
      {
        "id" => "123456",
        "name" => "Inbox",
        "system" => true
      },
      {
        "id" => "7890123",
        "name" => "MyName",
        "system" => false
      },
      {
        "id" => "135790",
        "name" => "Bin",
        "system" => true
      },
      {
        "id" => "24580",
        "name" => "Drafts",
        "system" => true
      },
      {
        "id" => "24589",
        "name" => "SentItems",
        "system" => true
      },
    ]]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      assert_enqueued_with(job: Govbox::SyncFolderJob, priority: 1000) do
        Govbox::SyncBoxJob.new.perform(box, initial_import: true)
      end
      end
  end

  test "schedules Govbox::SyncFolderJob with no priority unless initial box sync" do
    box = boxes(:ssd_main)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_folders, [200, [
      {
        "id" => "123456",
        "name" => "Inbox",
        "system" => true
      },
      {
        "id" => "7890123",
        "name" => "MyName",
        "system" => false
      },
      {
        "id" => "135790",
        "name" => "Bin",
        "system" => true
      },
      {
        "id" => "24580",
        "name" => "Drafts",
        "system" => true
      },
      {
        "id" => "24589",
        "name" => "SentItems",
        "system" => true
      },
    ]]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      assert_enqueued_with(job: Govbox::SyncFolderJob, priority: nil) do
        Govbox::SyncBoxJob.new.perform(box)
      end
    end
  end
end
