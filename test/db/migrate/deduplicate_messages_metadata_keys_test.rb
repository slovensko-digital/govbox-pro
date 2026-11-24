require "test_helper"
require Rails.root.glob("db/migrate/*_deduplicate_messages_metadata_keys.rb").first

class DeduplicateMessagesMetadataKeysTest < ActiveSupport::TestCase
  test "keeps the last value of a duplicated key so the metadata is readable again" do
    message = messages(:ssd_main_general_one)
    write_raw_metadata(message, '{"status":"created","fs_message_id":"123","status":"submit_fail"}')
    assert_nil Message.find(message.id).metadata, "guard: json 3 cannot read duplicated keys"

    migrate_up

    assert_equal({ "status" => "submit_fail", "fs_message_id" => "123" }, Message.find(message.id).metadata)
  end

  test "leaves metadata without duplicated keys untouched" do
    message = messages(:ssd_main_general_two)
    write_raw_metadata(message, '{"status": "created", "nested": {"status": "x"}}')

    migrate_up

    assert_equal '{"status": "created", "nested": {"status": "x"}}', raw_metadata(message)
  end

  private

  def migrate_up
    ActiveRecord::Migration.suppress_messages { DeduplicateMessagesMetadataKeys.new.migrate(:up) }
  end

  def write_raw_metadata(message, json)
    Message.where(id: message.id).update_all(["metadata = ?::json", json])
  end

  def raw_metadata(message)
    Message.where(id: message.id).pick(Arel.sql("metadata::text AS raw_metadata"))
  end
end
