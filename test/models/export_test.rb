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
