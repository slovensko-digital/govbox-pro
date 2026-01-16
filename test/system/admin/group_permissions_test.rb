# frozen_string_literal: true

require "application_system_test_case"

class GroupPermissionsTest < ApplicationSystemTestCase
  setup do
    BoxGroup.delete_all
    sign_in_as(:admin)
    @group = groups(:ssd_custom)
  end

  test "admin can add and remove box permissions" do
    box = boxes(:ssd_other)
    manage_permission_test(
      item: box,
      column_selector: "#boxes-column",
      search_result_selector: "#box-search-results",
      item_name_for_search: box.name
    )
  end

  test "admin can add and remove tag permissions" do
    tag = tags(:ssd_finance)
    manage_permission_test(
      item: tag,
      column_selector: "#tags-column",
      search_result_selector: "#tag-search-results",
      item_name_for_search: tag.name
    )
  end

  private

  def manage_permission_test(item:, column_selector:, search_result_selector:, item_name_for_search:)
    visit admin_tenant_permissions_path(tenants(:ssd))

    within("##{dom_id(@group)}") do
      click_link I18n.t("admin.groups.permissions.edit")
    end

    assert_text I18n.t("admin.groups.permissions.title", group_name: @group.name)

    within(column_selector) do
      assert_no_text item.name
    end

    within(column_selector) do
      fill_in "name_search", with: item_name_for_search
    end

    within(search_result_selector) do
      assert_selector "button", text: item_name_for_search, count: 1
      find("button", text: item_name_for_search).click
    end

    within(column_selector) do
      assert_text item.name
    end

    within("##{dom_id(item, :permission_row)}") do
      find("button[title='#{I18n.t("admin.groups.permissions.actions.delete")}']").click
    end

    within(column_selector) do
      assert_no_text item.name
    end
  end
end
