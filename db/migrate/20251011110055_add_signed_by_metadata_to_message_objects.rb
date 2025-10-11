class AddSignedByMetadataToMessageObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :message_objects, :signed_by_metadata, :jsonb, default: []
  end
end
