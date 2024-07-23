require "test_helper"

class Govbox::SubmitMessageDraftJobTest < ActiveJob::TestCase
  test "should create MessageSubmissionRequest and publish message_draft_submitted event" do
    message_draft = messages(:ssd_main_general_draft_two)
    box = message_draft.thread.box

    message_submission_requests_count = box.message_submission_requests.count

    sktalk_api_mock = Minitest::Mock.new
    sktalk_api_mock.expect :receive_and_save_to_outbox, [true, 200, {"receive_result": 0 , "save_to_outbox_result": 0}], [Hash]
    sktalk_api_mock.expect :receive_and_save_to_outbox_url, 'https://request_url.com'

    subscriber = Minitest::Mock.new
    subscriber.expect :perform_later, true, [:message_draft_submitted, message_draft]
    EventBus.subscribe_job(:message_draft_submitted, subscriber)

    ::Upvs::GovboxApi::SkTalk.stub :new, sktalk_api_mock do
      Govbox::SubmitMessageDraftJob.new.perform(message_draft)
    end

    assert_mock sktalk_api_mock
    assert_equal message_submission_requests_count + 1, box.message_submission_requests.reload.count
    assert_equal 'https://request_url.com', box.message_submission_requests.last.request_url
    assert_equal 200, box.message_submission_requests.last.response_status
    assert_mock subscriber

    # remove callback
    EventBus.class_variable_get(:@@subscribers_map)[:message_draft_submitted].pop
  end
end
