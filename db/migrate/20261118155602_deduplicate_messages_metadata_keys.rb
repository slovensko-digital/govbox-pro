# frozen_string_literal: true

# json 2.7.1 wrote keys set both as symbol and string twice, json 3 refuses to read such metadata
class DeduplicateMessagesMetadataKeys < ActiveRecord::Migration[8.1]
  def up
    rows = select_rows(<<~SQL.squish)
      SELECT id, metadata::text FROM messages
      WHERE json_typeof(metadata) = 'object'
        AND (SELECT count(*) FROM json_object_keys(metadata)) <> (SELECT count(DISTINCT k) FROM json_object_keys(metadata) k)
    SQL

    rows.each do |id, raw_metadata|
      # the last value wins, as json 2.7.1 read it
      Message.where(id: id).update_all(metadata: JSON.parse(raw_metadata, allow_duplicate_key: true))
    end
  end
end
