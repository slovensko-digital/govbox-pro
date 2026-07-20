# frozen_string_literal: true

require "application_system_test_case"

class MessageThreadsBulkExportTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    Searchable::MessageThread.reindex_all
    message_threads(:fs_accountants_thread1).assign_tag(tags(:accountants_basic_user_authors))
    sign_in_as(:accountants_basic)
  end

  test "export edit page shows message_direction radio buttons defaulting to all" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_selector "input[type=radio][name='export[settings][message_direction]'][value='all']"
    assert_selector "input[type=radio][name='export[settings][message_direction]'][value='inbox']"
    assert_selector "input[type=radio][name='export[settings][message_direction]'][value='outbox']"
    assert_text "Zahrnúť správy"
    assert_text "Všetky"
    assert_text "Len prijaté"
    assert_text "Len odoslané"

    all_radio = find("input[type=radio][value='all']")
    assert all_radio.checked?

    take_screenshot
  end

  test "export edit page shows vlakno.nazov in template variable reference" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    find("summary", text: "Dostupné premenné pre šablónu").click
    assert_text "{{ vlakno.nazov }}"
    assert_text "názov vlákna"

    take_screenshot
  end

  test "selecting outbox direction filters preview to show only outbox messages" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_text outbox_message.title
    assert_text inbox_message.title

    choose "Len odoslané"

    assert_text outbox_message.title
    assert_no_text inbox_message.title

    take_screenshot
  end

  test "selecting inbox direction filters preview to show only inbox messages" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    choose "Len prijaté"

    assert_text inbox_message.title
    assert_no_text outbox_message.title

    take_screenshot
  end

  test "date range inputs are shown on edit page" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_selector "input[type=date][name='export[settings][delivered_at_from]']"
    assert_selector "input[type=date][name='export[settings][delivered_at_to]']"
    assert_text "Dátum doručenia"
    assert_text "od"
    assert_text "do"

    take_screenshot
  end

  test "setting od date in future excludes current messages from preview" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)
    assert_text outbox_message.title

    future_date = (Date.today + 1.year).iso8601
    fill_in "export[settings][delivered_at_from]", with: future_date

    assert_no_text outbox_message.title

    take_screenshot
  end

  test "setting do date in past excludes current messages from preview" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)

    past_date = (Date.today - 1.year).iso8601
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "delivered_at_to" => past_date }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_no_text outbox_message.title

    take_screenshot
  end

  test "export with future od date hides messages; clearing it shows them again" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)

    future_date = (Date.today + 1.year).iso8601
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "delivered_at_from" => future_date }
    )

    visit edit_message_threads_bulk_export_path(export)
    assert_no_text outbox_message.title

    fill_in "export[settings][delivered_at_from]", with: ""
    find("input[name='export[settings][delivered_at_from]']").send_keys(:tab)

    assert_text outbox_message.title

    take_screenshot
  end

  test "thread with slash in title shows path with dash not extra folder in preview" do
    thread = message_threads(:fs_accountants_thread1)
    thread.update!(title: "DPH/2025/Q1")

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_text "DPH-2025-Q1/"
    assert_no_text "DPH/2025/Q1/"

    take_screenshot
  end

  test "Subor column is visible without horizontal scroll at desktop width" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_selector "th", text: "Súbor"

    subor_th = find("th", text: "Súbor")
    assert subor_th.visible?, "Súbor column header should be visible"

    take_screenshot
  end

  test "clicking truncated Nazov cell expands it to show full text" do
    thread = message_threads(:fs_accountants_thread1)
    thread.update!(title: "Very long thread title that will definitely be truncated in the narrow column")

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    visit edit_message_threads_bulk_export_path(export)

    nazov_cell = find("td[data-controller='expand-text']", text: /Very long thread title/, match: :first)
    assert nazov_cell.has_text?("▾"), "Indicator should start collapsed"

    nazov_cell.click
    assert nazov_cell.has_text?("▴"), "Indicator should change to expanded"

    take_screenshot

    nazov_cell.click
    assert nazov_cell.has_text?("▾"), "Indicator should collapse again"
  end

  test "clicking truncated Subor cell expands the file path" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true }
    )

    page.driver.browser.manage.window.resize_to(800, 1400)
    visit edit_message_threads_bulk_export_path(export)

    filepath_cell = find("td[data-controller='expand-text']:has(code[data-expand-content])", match: :first)

    assert filepath_cell.has_text?("▾"), "Indicator should be visible when path is truncated"
    filepath_cell.click
    assert filepath_cell.has_text?("▴"), "Indicator should change to expanded"

    take_screenshot
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end


  test "vlakno.nazov in template substitutes thread title in preview path" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    visit edit_message_threads_bulk_export_path(export)

    assert_text "#{thread.title}/"

    take_screenshot
  end
end
