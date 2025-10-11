class AddExportMetadataToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :export_metadata, :jsonb, null: false, default: {}
  end
end
