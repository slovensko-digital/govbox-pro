require "application_system_test_case"

class MessageDraftsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in_as(:basic)
  end

  test "user can create message draft as reply on replyable message" do
  end

  test "single draft submission schedules jobs with highest priority" do
    message_draft = messages(:ssd_main_draft)

    visit message_thread_path(message_draft.thread)

    assert_enqueued_with(job: Govbox::SubmitMessageDraftJob, queue: :highest_priority) do
      click_button "Odoslať"
    end
  end
end
