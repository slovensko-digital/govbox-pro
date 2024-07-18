require "application_system_test_case"

class MessageDraftsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:basic)
  end

  test "user can create message draft as reply on replyable message" do
  end

  test "alert is shown when user tries to send message without requested signatures present" do
    message_thread = message_threads(:ssd_main_draft_to_be_signed2)
    message_draft = messages(:ssd_main_draft_to_be_signed2_draft)

    visit message_thread_path(message_thread)

    within("#message_draft_#{message_draft.id}") do
      assert_button "Odoslať"

      accept_alert do
        click_button "Odoslať"
      end
    end
  end
end
