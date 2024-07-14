require "application_system_test_case"

class Fs::MessageDraftsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:accountants_basic)
  end

  test "user can upload a message draft" do
    visit message_threads_path

    click_button "Vytvoriť novú správu"
    click_link "Vytvoriť novú správu na finančnú správu"

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
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

  test "user can upload multiple message drafts at once" do
    visit message_threads_path

    click_button "Vytvoriť novú správu"
    click_link "Vytvoriť novú správu na finančnú správu"

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "2682_712"
    },
    [file_fixture("fs/dic1122334455_fs2682_712__v2py_2021.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      attach_file "content[]", [
        file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml"),
        file_fixture("fs/dic1122334455_fs2682_712__v2py_2021.xml")
      ]
      click_button "Nahrať správy"

      assert_text "Správy boli úspešne nahraté"

      Searchable::MessageThread.reindex_all

      visit message_threads_path

      message1 = Fs::MessageDraft.second_to_last
      message2 = Fs::MessageDraft.last

      within_thread_in_listing(message1.thread) do
        assert_text "Podanie pre FS (Správa daní) - platné od 1.4.2024"
        assert_text "Finančná správa"

        within_tags do
          assert_text "Rozpracované"
        end
      end

      within_thread_in_listing(message2.thread) do
        assert_text "Vyhlásenie o poukázaní sumy do výšky 2% (3%) zaplatenej dane za zdaňovacie obdobie 2021"
        assert_text "Finančná správa"

        within_tags do
          assert_text "Rozpracované"
        end
      end
    end
  end

  test "user can upload message draft only if any FS box exists & :fs_api feature is enabled" do
    sign_in_as(:basic)

    visit message_threads_path

    click_button "Vytvoriť novú správu"
    assert_not has_link? "Vytvoriť novú správu na finančnú správu"
  end
end
