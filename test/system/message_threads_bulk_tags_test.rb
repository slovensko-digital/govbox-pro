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

    within("[data-test='message_thread_#{thread_general.id}']") do
      within("[data-test='tags']") do
        assert_text "Finance"
        assert_text "Legal"
        assert_text "Other"
      end
    end

    within("[data-test='message_thread_#{thread_issue.id}']") do
      within("[data-test='tags']") do
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

    fully_check_indeterminate_checkbox("Legal")

    within("#tags-assignment-diff") do
      assert_text "Pridajú sa"
      assert_text "Legal"
    end

    uncheck "Legal"

    within("#tags-assignment-diff") do
      assert_text "Odoberú sa"
      assert_text "Legal"
    end

    check "Print"

    within("#tags-assignment-diff") do
      within("[data-test='to_be_added']") do
        assert_text "Print"
      end

      within("[data-test='to_be_removed']") do
        assert_text "Legal"
      end
    end

    fill_in "name_search_query", with: "Struction"

    within("#tags-assignment-list") do
      refute_text "Legal"
      refute_text "Print"
    end

    check "Construction"

    within("#tags-assignment-diff") do
      within("[data-test='to_be_added']") do
        assert_text "Construction"
        assert_text "Print"
      end

      within("[data-test='to_be_removed']") do
        assert_text "Legal"
      end
    end

    check "Struction"

    within("#tags-assignment-list") do
      assert_text "Legal"
      assert_text "Print"
      assert_text "Struction"
    end

    within("#tags-assignment-diff") do
      within("[data-test='to_be_added']") do
        assert_text "Construction"
        assert_text "Print"
        assert_text "Struction"
      end

      within("[data-test='to_be_removed']") do
        assert_text "Legal"
      end
    end

    click_button "Uložiť zmeny"

    assert_text "Priradenie štítkov bolo upravené"

    within("[data-test='message_thread_#{thread_issue.id}']") do
      within("[data-test='tags']") do
        assert_text "Finance"
        assert_text "Print"
        assert_text "Struction"
        assert_text "Construction"

        refute_text "Other"
        refute_text "Legal"
      end
    end

    within("[data-test='message_thread_#{thread_general.id}']") do
      within("[data-test='tags']") do
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

  def fully_check_indeterminate_checkbox(finder)
    checkbox = find(:checkbox, "Legal")

    assert_equal ["=", true],
                 [checkbox.value, checkbox.checked?],
                 "indeterminate checkbox(#{finder}) is expected to be checked with '=' value"

    checkbox.uncheck # yes, unchecking 'indeterminate' checkbox makes it fully checked (implementation detail)
  end

end
