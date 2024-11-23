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
      Govbox::SyncBoxJob.set(job_context: :later).perform_now(box)
      assert_equal "Govbox::SyncFolderJob", GoodJob::Job.last.job_class
      assert_equal 1000, GoodJob::Job.last.priority
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
      Govbox::SyncBoxJob.perform_now(box)
      assert_equal "Govbox::SyncFolderJob", GoodJob::Job.first.job_class
      assert_equal 0, GoodJob::Job.first.priority
    end
  end
end
