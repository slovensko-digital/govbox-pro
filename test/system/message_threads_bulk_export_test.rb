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
