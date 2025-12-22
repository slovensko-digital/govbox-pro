require "test_helper"

class Fs::SubmitMessageDraftJobTest < ActiveJob::TestCase
  test "marks submission failed and tags draft when box is inactive" do
    message_draft = messages(:fs_accountants_draft)
    submission_error_tag = tags(:accountants_submission_error_tag)
    message_draft.thread.box.update!(active: false)

    fs_client = Minitest::Mock.new

    message_draft.stub :valid?, true do
      FsEnvironment.stub :fs_client, fs_client do
        assert_raises(Fs::SubmitMessageDraftJob::SubmissionError) do
          Fs::SubmitMessageDraftJob.new.perform(message_draft)
        end
      end
    end

    message_draft.reload
    assert_equal "submit_fail", message_draft.metadata["status"]
    assert_includes message_draft.tags, submission_error_tag
    assert_includes message_draft.thread.tags, submission_error_tag
  ensure
    fs_client.verify if fs_client.respond_to?(:verify)
  end
end
