require "test_helper"
require "helpers/good_job_helper"

class Govbox::DownloadMessageJobTest < ActiveJob::TestCase
  include GoodJobHelper

  test "raises with response status and body if message cannot be fetched" do
    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_message, [404, { "message" => "Not found" }], [123]

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      error = assert_raises(RuntimeError) { Govbox::DownloadMessageJob.new.perform(govbox_folders(:ssd_one), 123) }
      assert_match(/404.*Not found/, error.message)
    end
  end

  test "enqueues only one job per message" do
    folder = govbox_folders(:ssd_one)

    2.times { Govbox::DownloadMessageJob.perform_later(folder, 123) }
    Govbox::DownloadMessageJob.perform_later(folder, 456)

    assert_equal 2, GoodJob::Job.where(job_class: "Govbox::DownloadMessageJob").count
  end
end
