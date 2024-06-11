require "application_system_test_case"

class Fs::MessageDraftsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:accountants_basic)
  end

  test "user can upload a single message draft" do
    visit message_threads_path

    click_link "Nahrať nové správy"

    attach_file "content[]", file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml")

    click_button "Nahrať správy"

    assert_text "Správy boli úspešne nahraté"

    assert_content "Podanie pre FS (Správa daní) - platné od 1.4.2024"
    assert_content "Rozpracované"

    within_frame(find("iframe")) do
      assert_text "Všeobecné podanie - správa daní"
      assert_text "Daňové identifikačné číslo:\n1122334455"
    end
  end
end
