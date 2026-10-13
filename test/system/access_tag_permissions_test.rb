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

  %i[ssd_all ssd_signers ssd_basic_user].each do |fixture|
    test "admin can revoke access tag management for #{fixture} through permissions UI" do
      group = groups(fixture)
      group.update!(can_manage_access_tags: true)
      sign_in_as(:admin)
      visit admin_tenant_permissions_path(tenants(:ssd))

      within("##{ActionView::RecordIdentifier.dom_id(group)}") do
        find("a[title='#{I18n.t('admin.groups.permissions.edit')}']").click
      end

      assert_current_path edit_permissions_admin_tenant_group_path(tenants(:ssd), group)
      within("#tags-column") do
        assert_selector "button[role=switch][aria-checked=true]"
        find("button[role=switch]").click
        assert_selector "button[role=switch][aria-checked=false]"
      end
      refute group.reload.can_manage_access_tags
    end
  end

  test "locked mixed bulk assignment stays indeterminate through search" do
    tag = tags(:ssd_legal)
    tag.groups << groups(:ssd_custom)
    sign_in_as(:basic)
    visit message_threads_path
    check "message_thread_#{@thread.id}"
    assert_text "1 označená správa"
    check "message_thread_#{message_threads(:ssd_main_issue).id}"
    assert_text "2 označené správy"
    click_button "Hromadné akcie"
    click_button "Upraviť štítky"
    assert_text "Úprava štítkov v 2 vláknach"

    assert_locked_mixed_state(tag)
    fill_in "name_search_query", with: "Print"
    within("#tags-assignment-list") { assert_no_text "Legal" }
    fill_in "name_search_query", with: ""
    within("#tags-assignment-list") { assert_text "Legal" }
    assert_locked_mixed_state(tag)
    assert_no_selector "input[name='tags_assignments[new][#{tag.id}]']"
  end

  [false, true].each do |bulk|
    test "#{bulk ? 'bulk' : 'single'} save preserves locked assignments while applying classification changes" do
      locked_tag = tags(:ssd_legal)
      locked_tag.groups << groups(:ssd_custom)
      threads = bulk ? [@thread, message_threads(:ssd_main_issue)] : [@thread]
      original_assignments = threads.to_h do |thread|
        [thread.id, [@finance, locked_tag].map { |tag| thread.tags.exists?(tag.id) }]
      end
      sign_in_as(:basic)

      if bulk
        visit message_threads_path
        check "message_thread_#{@thread.id}"
        assert_text "1 označená správa"
        check "message_thread_#{threads.last.id}"
        assert_text "2 označené správy"
        click_button "Hromadné akcie"
        click_button "Upraviť štítky"
        assert_text "Úprava štítkov v 2 vláknach"
        assert_locked_mixed_state(locked_tag)
      else
        visit message_thread_path(@thread)
        click_link "Upraviť štítky"
      end

      [@finance, locked_tag].each do |tag|
        checkbox = find("#new_tags_assignments_#{tag.id}")
        assert checkbox.disabled?
        original_value = checkbox.value
        original_checked = checkbox.checked?
        checkbox.click
        assert_equal original_value, checkbox.value
        assert_equal original_checked, checkbox.checked?
        assert_no_selector "input[name='tags_assignments[new][#{tag.id}]']", visible: :all
      end

      check "Print"
      click_button "Uložiť zmeny (1)"
      assert_no_selector "#tags-assignment-list"

      threads.each do |thread|
        thread.reload
        assert_equal original_assignments.fetch(thread.id),
                     [@finance, locked_tag].map { |tag| thread.tags.exists?(tag.id) }
        assert_includes thread.tags, tags(:ssd_print)
      end
    end
  end

  private

  def assert_locked_mixed_state(tag)
    checkbox = find("#new_tags_assignments_#{tag.id}")
    assert checkbox.disabled?
    assert_equal "=", checkbox.value
    assert checkbox.checked?
    assert page.evaluate_script("document.getElementById('new_tags_assignments_#{tag.id}').indeterminate")
  end

  def assert_finance_state(permission)
    checkbox = find("#new_tags_assignments_#{@finance.id}")
    assert checkbox.checked?
    assert_equal !permission, checkbox.disabled?
  end
end
