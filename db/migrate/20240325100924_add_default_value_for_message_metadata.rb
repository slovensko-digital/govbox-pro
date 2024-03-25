class AddDefaultValueForMessageMetadata < ActiveRecord::Migration[7.1]
  def change
    change_column :messages, :metadata, :json, default: {}
  end
end
