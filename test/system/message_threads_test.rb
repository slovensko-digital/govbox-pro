require "application_system_test_case"

class MessageThreadsTest < ApplicationSystemTestCase
  setup do
    # TODO find a better way without warning
    @old_per_page = MessageThreadCollection::PER_PAGE
    MessageThreadCollection.const_set("PER_PAGE", 1) # change per page to test infinite scrolling

    Searchable::MessageThread.reindex_all

    mock_auth_and_sign_in_as(users(:basic))
  end

  teardown do
    MessageThreadCollection.const_set("PER_PAGE", @old_per_page)
  end

  test "threads listing" do
    visit message_threads_path

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within("[data-test='message_thread_#{thread_general.id}']") do
      assert_text "General"
      assert_text "Social Department"

      within("[data-test='tags']") do
        assert_text "Finance"
        assert_text "Legal"
      end
    end

    within("[data-test='message_thread_#{thread_issue.id}']") do
      assert_text "Issue"
      assert_text "SD Services"

      within("div[data-test='tags']") do
        assert_text "Finance"
      end
    end

    within("[data-test='sidebar']") do
      within("div[data-test='filters']") do
        assert_text "With General text"
        assert_text "With Legal text"

        # other tenant
        refute_text "Urgent"
      end

      within("[data-test='tags']") do
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

  test "fulltext search" do
    visit message_threads_path

    fill_in "search", with: "Social Department"
    find("#search").send_keys('keyword', :enter)

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within("[data-test='message_thread_#{thread_general.id}']") do
      assert_text "General"
      assert_text "Social Department"
    end

    refute_selector("[data-test='message_thread_#{thread_issue.id}']")
  end

  test "filter by tag from sidebar" do
    visit message_threads_path

    within("[data-test='sidebar']") do
      within("[data-test='tags']") do
        click_link "Legal"
      end
    end

    thread_general = message_threads(:ssd_main_general)
    thread_issue = message_threads(:ssd_main_issue)

    within("[data-test='message_thread_#{thread_general.id}']") do
      assert_text "General"
      assert_text "Social Department"
    end

    refute_selector("[data-test='message_thread_#{thread_issue.id}']")
  end

  test "thread detail" do
    visit message_threads_path

    thread_general = message_threads(:ssd_main_general)
    message_one = messages(:ssd_main_general_one)
    message_two = messages(:ssd_main_general_two)
    message_three = messages(:ssd_main_general_three)

    draft_one = message_drafts(:ssd_main_general_draft_one)

    within("[data-test='message_thread_#{thread_general.id}']") do
      click_link
    end

    within("[data-test='thread-detail']") do
      within("[data-test='header']") do
        within("[data-test='title']") do
          assert_text "General agenda SSD"
        end

        within("[data-test='tags']") do
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

        assert_button "Odoslať"
      end
    end
  end
end
