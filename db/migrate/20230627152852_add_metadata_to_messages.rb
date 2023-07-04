class AddMetadataToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :metadata, :json
  end
end
