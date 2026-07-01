require "test_helper"

class ExportTest < ActiveSupport::TestCase
  fixtures :users, :message_threads, :messages, :message_objects

  def setup
    Current.user = users(:basic)
  end

  test 'new export can be created empty (validation skipped on create)' do
    export = Export.new(user: Current.user, message_thread_ids: [], settings: {})
    assert export.valid?, 'new export should be valid even without summary/messages'
  end

  test 'update fails with neither summary nor messages selected' do
    export = Export.create!(user: Current.user, message_thread_ids: [], settings: { 'summary' => true })
    export.settings['summary'] = false
    export.settings['messages'] = false
    refute export.valid?, 'export should be invalid with no summary and no messages'
    expected = I18n.t('activerecord.errors.models.export.attributes.base.empty_selection')
    assert_includes export.errors.full_messages.join, expected, 'error message should match translation'
  end

  test 'update passes when summary selected' do
    export = Export.create!(user: Current.user, message_thread_ids: [], settings: { 'summary' => true })
    assert export.update(settings: { 'summary' => true, 'messages' => false })
  end

  test 'update passes when messages selected' do
    export = Export.create!(user: Current.user, message_thread_ids: [], settings: { 'messages' => true })
    export.settings['messages'] = true
    assert export.valid?
  end

  test "export_object_filepath substitutes vlakno.nazov" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    path = export.export_object_filepath(object)
    assert path.start_with?(thread.title), "Expected path to start with thread title '#{thread.title}', got '#{path}'"
  end

  test "export_object_filepath handles nil thread title gracefully" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    thread.stub(:title, nil) do
      message.stub(:thread, thread) do
        object.stub(:message, message) do
          assert_nothing_raised { export.export_object_filepath(object) }
        end
      end
    end
  end

  test "filtered_messages returns all messages when direction is 'all'" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "message_direction" => "all" }
    )

    result = export.filtered_messages(thread)
    inbox_count = thread.messages.inbox.count
    outbox_count = thread.messages.outbox.count
    assert_equal inbox_count + outbox_count, result.count
  end

  test "filtered_messages returns only outbox messages when direction is 'outbox'" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "message_direction" => "outbox" }
    )

    result = export.filtered_messages(thread)
    assert result.all?(&:outbox), "Expected only outbox messages"
    assert_equal thread.messages.outbox.count, result.count
  end

  test "filtered_messages returns only inbox messages when direction is 'inbox'" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "message_direction" => "inbox" }
    )

    result = export.filtered_messages(thread)
    assert result.none?(&:outbox), "Expected only inbox messages"
    assert_equal thread.messages.inbox.count, result.count
  end

  test "filtered_messages defaults to all messages when setting is missing" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: {}
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert_equal thread.messages.count, result.count
  end

  test "normalize_settings sets message_direction to 'all' when blank" do
    export = Export.new(user: Current.user, settings: {})
    export.valid?
    assert_equal "all", export.settings["message_direction"]
  end

  test "normalize_settings rejects unknown message_direction values" do
    export = Export.new(user: Current.user, settings: { "message_direction" => "sideways" })
    export.valid?
    assert_equal "all", export.settings["message_direction"]
  end

  test "normalize_settings preserves valid message_direction values" do
    %w[all inbox outbox].each do |direction|
      export = Export.new(user: Current.user, settings: { "message_direction" => direction })
      export.valid?
      assert_equal direction, export.settings["message_direction"]
    end
  end

  test "filtered_messages with only from date returns messages on or after that date" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_msg = messages(:fs_accountants_thread1_outbox_message)
    future_date = outbox_msg.delivered_at.to_date + 1.day

    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "delivered_at_from" => future_date.iso8601 }
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert_not_includes result, outbox_msg
  end

  test "filtered_messages with only to date returns messages on or before that date" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_msg = messages(:fs_accountants_thread1_outbox_message)
    past_date = outbox_msg.delivered_at.to_date - 1.day

    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "delivered_at_to" => past_date.iso8601 }
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert_not_includes result, outbox_msg
  end

  test "filtered_messages with both dates uses full range" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_msg = messages(:fs_accountants_thread1_outbox_message)
    date = outbox_msg.delivered_at.to_date

    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "delivered_at_from" => date.iso8601, "delivered_at_to" => date.iso8601 }
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert_includes result, outbox_msg
  end

  test "filtered_messages with no dates applies no date filtering" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: {}
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert_equal thread.messages.count, result.count
  end

  test "filtered_messages with date range combined with inbox direction" do
    thread = message_threads(:fs_accountants_thread1)
    inbox_msg = messages(:fs_accountants_thread1_inbox_message)
    date = inbox_msg.delivered_at.to_date

    export = Export.new(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "message_direction" => "inbox", "delivered_at_from" => date.iso8601, "delivered_at_to" => date.iso8601 }
    )
    export.valid?

    result = export.filtered_messages(thread)
    assert result.all? { |m| !m.outbox }, "should only return inbox messages"
    assert_includes result, inbox_msg
  end

  test "normalize_settings parses valid ISO-8601 date string for delivered_at_from" do
    export = Export.new(user: Current.user, settings: { "delivered_at_from" => "2025-01-15" })
    export.valid?
    assert_equal Date.new(2025, 1, 15), export.settings["delivered_at_from"]
  end

  test "normalize_settings parses valid ISO-8601 date string for delivered_at_to" do
    export = Export.new(user: Current.user, settings: { "delivered_at_to" => "2025-06-30" })
    export.valid?
    assert_equal Date.new(2025, 6, 30), export.settings["delivered_at_to"]
  end

  test "normalize_settings rejects invalid date string, sets nil" do
    export = Export.new(user: Current.user, settings: { "delivered_at_from" => "not-a-date" })
    export.valid?
    assert_nil export.settings["delivered_at_from"]
  end

  test "normalize_settings accepts nil for dates" do
    export = Export.new(user: Current.user, settings: { "delivered_at_from" => nil })
    export.valid?
    assert_nil export.settings["delivered_at_from"]
  end

  test "normalize_settings accepts empty string for dates, sets nil" do
    export = Export.new(user: Current.user, settings: { "delivered_at_from" => "" })
    export.valid?
    assert_nil export.settings["delivered_at_from"]
  end

  test "export is invalid when delivered_at_from is after delivered_at_to" do
    export = Export.create!(user: Current.user, message_thread_ids: [], settings: { "summary" => true })
    export.settings["delivered_at_from"] = "2025-06-30"
    export.settings["delivered_at_to"]   = "2025-01-01"
    refute export.valid?
    assert export.errors[:base].any? { |e| e.include?("od") || e.include?("do") || e.include?("dátum") || e.include?("rozsah") || e.include?("range") || e.include?("from") || e.include?("to") }
  end

  test "export is valid when delivered_at_from equals delivered_at_to" do
    export = Export.create!(user: Current.user, message_thread_ids: [], settings: { "summary" => true })
    export.settings["delivered_at_from"] = "2025-06-30"
    export.settings["delivered_at_to"]   = "2025-06-30"
    assert export.valid?
  end

  test "export_object_filepath replaces slash in thread title" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    thread.stub(:title, "DPH/2025/Q1") do
      message.stub(:thread, thread) do
        object.stub(:message, message) do
          path = export.export_object_filepath(object)
          parts = path.split("/")
          refute parts.any? { |p| p.empty? }, "Expected no empty path segments from slash in title, got: #{path}"
          assert_equal "DPH-2025-Q1", parts.first, "Slash in title should be replaced with dash"
        end
      end
    end
  end

  test "export_object_filepath replaces slash in message object name" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "vlakno/{{ subor.nazov }}" } }
    )

    MessageObjectHelper.stub(:displayable_name, "report/2025/file.pdf") do
      path = export.export_object_filepath(object)
      assert_equal "vlakno/report-2025-file.pdf", path, "Slash in object name should be replaced with dash"
    end
  end

  test "export_object_filepath replaces multiple slashes in thread title" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    thread.stub(:title, "a/b/c") do
      message.stub(:thread, thread) do
        object.stub(:message, message) do
          path = export.export_object_filepath(object)
          assert_equal "a-b-c", path.split("/").first, "Multiple slashes should all be replaced"
        end
      end
    end
  end

  test "export_object_filepath still blocks path traversal with ../" do
    thread = message_threads(:fs_accountants_thread1)
    message = messages(:fs_accountants_thread1_outbox_message)
    object = message.objects.first

    export = Export.create!(
      user: Current.user,
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "../{{ vlakno.id }}/{{ subor.nazov }}" } }
    )

    path = export.export_object_filepath(object)
    refute path.include?("../"), "Path traversal ../ should be stripped"
  end

  test 'file_name returns old naming logic if old file exists' do
    export = exports(:one)
    old_name = "#{export.user.tenant.id}/govbox-pro-export-#{export.created_at.to_date}.zip"

    File.stub(:exist?, true) do
      assert_equal old_name, export.file_name
    end
  end

  test 'file_name returns new naming logic if old file does not exist' do
    export = exports(:one)
    new_name = "#{export.user.tenant.id}/govbox-pro-export-##{export.id}-#{export.created_at.to_date}.zip"

    File.stub(:exist?, false) do
      assert_equal new_name, export.file_name
    end
  end
end
