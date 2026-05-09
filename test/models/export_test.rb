require "test_helper"

class ExportTest < ActiveSupport::TestCase
  fixtures :users

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
