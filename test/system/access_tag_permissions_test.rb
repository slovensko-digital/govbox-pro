require "application_system_test_case"

class AccessTagPermissionsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all
    @thread = message_threads(:ssd_main_general)
    @finance = tags(:ssd_finance)
  end

  [false, true].each do |permission|
    [false, true].each do |bulk|
      test "#{bulk ? 'bulk' : 'single'} assignment preserves state with permission #{permission}" do
        groups(:ssd_basic_user).update!(can_manage_access_tags: permission)
        sign_in_as(:basic)

        if bulk
          visit message_threads_path
          check "message_thread_#{@thread.id}"
          assert_text "1 označená správa"
          check "message_thread_#{message_threads(:ssd_main_issue).id}"
          assert_text "2 označené správy"
          click_button "Hromadné akcie"
          click_button "Upraviť štítky"
          assert_text "Úprava štítkov v 2 vláknach"
        else
          visit message_thread_path(@thread)
          click_link "Upraviť štítky"
        end

        assert_finance_state(permission)
        check "Print"
        assert_button "Uložiť zmeny (1)"
        assert_finance_state(permission)

        fill_in "name_search_query", with: "Print"
        within("#tags-assignment-list") { assert_no_text "Finance" }
        fill_in "name_search_query", with: ""
        within("#tags-assignment-list") { assert_text "Finance" }
        assert_finance_state(permission)
        assert_checked_field "Print"

        if permission
          uncheck "Finance"
          assert_button "Uložiť zmeny (2)"
        else
          assert_no_selector "input[name='tags_assignments[new][#{@finance.id}]']"
        end
      end
    end
  end

  test "admin group permission is shown as always enabled" do
    sign_in_as(:admin)
    visit edit_permissions_admin_tenant_group_path(tenants(:ssd), groups(:ssd_admins))

    within("#tags-column") do
      assert_text I18n.t("admin.groups.permissions.access_tags_always_enabled")
      assert_no_selector "input[name=can_manage_access_tags]"
    end
  end

  private

  def assert_finance_state(permission)
    checkbox = find("#new_tags_assignments_#{@finance.id}")
    assert checkbox.checked?
    assert_equal !permission, checkbox.disabled?
  end
end
