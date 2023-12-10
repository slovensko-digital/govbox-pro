require "application_system_test_case"

class AuditLogTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    sign_in_as(:admin)
  end

  test "admin can access thread audit logs" do
    visit message_thread_path(message_threads(:ssd_main_general))

    click_button "message-thread-options"
    click_link "Auditné záznamy"

    assert_text "Auditné záznamy pre vlákno"

    click_link "Export CSV"
  end

  test "admin can access user audit logs" do
    visit root_path

    click_link "Nastavenia"

    click_link "Používatelia"

    within("#user_#{users(:admin).id}") do
      click_link "Auditné záznamy používateľa"
    end

    assert_text "Auditné záznamy pre používateľa"

    click_link "Export CSV"
  end
end
