require "application_system_test_case"

class Upvs::MessageDraftsTest < ApplicationSystemTestCase
  test "user can create message draft from template only if any UPVS box exists" do
    sign_in_as(:accountants_basic)

    visit message_threads_path

    click_button "Vytvoriť novú správu"
    assert_not has_link? "Napísať novú správu na slovensko.sk"
  end

  test "user can create message draft from Všeobecná agenda MessageTemplate" do
  end

  test "user can create message draft from CRAC MessageTemplate" do
  end

  test "user can update message draft content" do
  end

  test "user can submit message draft" do
  end

  test "user can delete message draft" do
  end
end
