require "test_helper"

class Automation::RuleTest < ActiveSupport::TestCase
  test "should run an automation on message thread created" do
    box = boxes(:one)

    box.tenant.automation_rules.create!(name: 'Rule Test', trigger_event: :message_thread_created)

    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      folder: folders(:one),
      title: 'Všeobecná agenda',
      delivered_at: Time.current,
    )

    thread_no_match = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: SecureRandom.uuid,
      folder: folders(:one),
      title: 'Iná agenda',
      delivered_at: Time.current,
    )

    assert_equal Folder.second!, thread.folder
    assert_equal folders(:one), thread_no_match.folder
  end
end
