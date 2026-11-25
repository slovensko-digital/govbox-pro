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
      item_name_for_search: box.name
    )
  end

  test "the all-boxes switch applies to the group without removing individual box permissions" do
    box = boxes(:ssd_other)
    @group.box_groups.create!(box: box)
    visit edit_permissions_admin_tenant_group_path(tenants(:ssd), @group)

    assert_selector "##{dom_id(box, :permission_row)}"
    click_button "Prístup ku všetkým schránkam"
    within("#boxes-column") do
      assert_text "Skupina má prístup ku všetkým schránkam."
      assert_no_selector "##{dom_id(box, :permission_row)}"
    end
    assert @group.reload.all_boxes_permission?

    click_button "Prístup ku všetkým schránkam"
    within("#boxes-column") do
      assert_selector "##{dom_id(box, :permission_row)}"
      assert_no_text "Skupina má prístup ku všetkým schránkam."
    end
    refute @group.reload.all_boxes_permission?
  end

  test "admin can navigate to tags management from permissions" do
    visit admin_tenant_permissions_path(tenants(:ssd))

    click_link "Nastaviť štítky"

    assert_current_path admin_tenant_tags_path(tenants(:ssd))
    assert_text "Štítky"
  end

  test "admin can add and remove tag permissions" do
    tag = tags(:ssd_finance)
    manage_permission_test(
      item: tag,
      column_selector: "#tags-column",
      item_name_for_search: tag.name
    )
  end

  private

  def manage_permission_test(item:, column_selector:, item_name_for_search:)
    visit admin_tenant_permissions_path(tenants(:ssd))

    within("##{dom_id(@group)}") do
      click_link I18n.t("admin.groups.permissions.edit")
    end

    assert_text I18n.t("admin.groups.permissions.title", group_name: @group.name)

    within(column_selector) do
      assert_no_text item.name
    end

    fill_in "name_search", with: item_name_for_search

    within("#boxes-and-tags-search-results") do
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
