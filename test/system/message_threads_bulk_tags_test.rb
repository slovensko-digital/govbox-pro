require "application_system_test_case"

class MessageThreadsBulkTagsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    @thread_general = message_threads(:ssd_main_general)

    sign_in_as(:basic)
  end

  test "a user can change tags on multiple threads with bulk action" do
    visit message_threads_path

    thread_issue = message_threads(:ssd_main_issue)
    thread_general = message_threads(:ssd_main_general)

    within_thread_in_listing(thread_general) do
      within_tags do
        assert_text "Finance"
        assert_text "Legal"
        assert_text "Other"
      end
    end

    within_thread_in_listing(thread_issue) do
      within_tags do
        assert_text "Finance"
      end
    end

    check "message_thread_#{thread_issue.id}"
    assert_text "1 označená správa"

    check "message_thread_#{thread_general.id}"
    assert_text "2 označené správy"

    click_button "Hromadné akcie"

    click_button "Upraviť štítky"

    assert_text "Úprava štítkov v 2 vláknach"

    check_indeterminate_checkbox("Legal")

    uncheck "Legal"

    check "Print"

    fill_in "name_search_query", with: "Struction"

    within("#tags-assignment-list") do
      refute_text "Legal"
      refute_text "Print"
    end

    check "Construction"

    check "Struction"

    within("#tags-assignment-list") do
      assert_text "Legal"
      assert_text "Print"
      assert_text "Struction"
    end

    click_button "Uložiť zmeny"

    assert_text "Priradenie štítkov bolo upravené"

    within_thread_in_listing(thread_issue) do
      within_tags do
        assert_text "Finance"
        assert_text "Print"
        assert_text "Struction"
        assert_text "Construction"

        refute_text "Other"
        refute_text "Legal"
      end
    end

    within_thread_in_listing(thread_general) do
      within_tags do
        assert_text "Finance"
        assert_text "Print"
        assert_text "Struction"
        assert_text "Construction"
        assert_text "Other"

        refute_text "Legal"
      end
    end
  end

  private

  def check_indeterminate_checkbox(finder)
    checkbox = find(:checkbox, finder)

    assert_equal ["=", true],
                 [checkbox.value, checkbox.checked?],
                 "indeterminate checkbox(#{finder}) is expected to be checked with '=' value"

    checkbox.uncheck # yes, unchecking 'indeterminate' checkbox makes it fully checked (implementation detail)
  end

end
