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
end
