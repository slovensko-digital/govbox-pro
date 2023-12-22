require "application_system_test_case"

class MessageDraftsSigningTest < ApplicationSystemTestCase
  setup do
    @thread_general = message_threads(:ssd_main_general)
    @first_draft = @thread_general.messages.find { |message| message.draft? }

    GroupMembership.create!(user: users(:basic), group: groups(:ssd_signers))

    sign_in_as(:basic)
  end

  test "user can request a signature from a user on message drafts" do
    visit message_thread_path(@thread_general)

    within_message_in_thread(@first_draft) do
      click_button "option-menu-button"
      click_link "Vyžiadať podpis"
    end

    check "Hlavný dokument"
    click_button "Vybrať podpisujúcich"

    click_button "Späť na výber dokumentov"
    click_button "Vybrať podpisujúcich"

    check "Basic user"
    click_button "Uložiť zmeny"

    assert_text "štítky boli upravené"

    assert_text "Na podpis"
    assert_text "Na podpis: Basic user"
  end
end
