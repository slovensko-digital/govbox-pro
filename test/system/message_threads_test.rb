require "application_system_test_case"

class MessageThreadsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    silence_warnings do
      @old_value = MessageThreadCollection.const_get("PER_PAGE")
      MessageThreadCollection.const_set("PER_PAGE", 1)
    end

    sign_in_as(:basic)
  end

  teardown do
    silence_warnings do
      MessageThreadCollection.const_set("PER_PAGE", @old_value)
    end
  end

  test "user can see threads he has access to" do
    visit message_threads_path

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within_thread_in_listing(thread_general) do
      assert_text "General"
      assert_text "Social Department"

      within_tags do
        assert_text "Finance"
        assert_text "Legal"
        assert_text "Other"
      end
    end

    within_thread_in_listing(thread_issue) do
      assert_text "Issue"
      assert_text "SD Services"

      within_tags do
        assert_text "Finance"
      end
    end

    within_sidebar do
      within_filters do
        assert_text "With General text"
        assert_text "With Legal text"

        # other tenant
        refute_text "Urgent"
      end

      within_tags do
        assert_text "Finance"
        assert_text "Legal"
        assert_text "ExtVisible"
        assert_text "Print"

        # non visible
        refute_text "Hidden"
        refute_text "External"

        # other tenant
        refute_text "Special"
      end
    end
  end

  test "user can use fulltext search to filter threads" do
    visit message_threads_path

    fill_in "search", with: "Social Department"
    find("#search").send_keys(:enter)

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within_thread_in_listing(thread_general) do
      assert_text "General"
      assert_text "Social Department"
      refute_text "Issue"
    end

    refute_selector(thread_in_listing_selector(thread_issue))
  end

  test "user can filter by tag from sidebar" do
    visit message_threads_path

    within_sidebar do
      within_tags do
        click_link "Legal"
      end
    end

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within_thread_in_listing(thread_general) do
      assert_text "General"
      assert_text "Social Department"
    end

    refute_selector(thread_in_listing_selector(thread_issue))
  end

  test "user can go to a thread detail of the thread he has access to" do
    visit message_threads_path

    thread_general = message_threads(:ssd_main_general)
    message_one = messages(:ssd_main_general_one)
    message_two = messages(:ssd_main_general_two)
    message_three = messages(:ssd_main_general_three)

    draft_one = messages(:ssd_main_general_draft_one)

    within_thread_in_listing(thread_general) do
      click_link
    end

    within("[data-test='thread-detail']") do
      within("[data-test='header']") do
        within("[data-test='title']") do
          assert_text "General agenda SSD"
        end

        within_tags do
          assert_text "Finance"
          assert_text "Legal"
        end
      end

      within("#thread-note") do
        assert_text "Insider Note1"
      end

      within("#message_#{message_one.id}") do
        assert_text "The First Message"
        assert_text "Social Department"

        within_frame(find("iframe")) do
          assert_text "Visualization 1"
        end
      end

      within("#message_#{message_two.id}") do
        assert_text "The Second Message"
        assert_text "Neznámy"

        assert_button "Prevziať správu"

        within_frame(find("iframe")) do
          assert_text "Visualization 2"
        end
      end

      within("#message_#{message_three.id}") do
        assert_text "The Collapsed Message"
      end

      within("#message_draft_#{draft_one.id}") do
        within_frame(find("iframe")) do
          assert_text "Reply to something"
        end

      within("#submission_message_draft_#{draft_one.id}") do
        assert_button "Odoslať"
      end
    end
  end

  test "user can go to a thread detail and reply to last replyable message" do
    thread_issue = message_threads(:ssd_main_issue)
    message_two = messages(:ssd_main_issue_two)

    visit message_thread_path thread_issue
    within_message_in_thread message_two do
      click_button "Odpovedať"
    end

    within '#new_drafts' do
      fill_in "Text", with: "Testovacie telo"
      fill_in "Predmet", with: "Testovaci predmet"
      click_button "Odoslať"
    end

    assert_text "Správa bola zaradená na odoslanie"
  end
end
