class AddDefaultValueForMessageMetadata < ActiveRecord::Migration[7.1]
  def up
    change_column :messages, :metadata, :json, default: {}

    ::Message.where(metadata: nil).update(metadata: {})
  end

  def down
    change_column :messages, :metadata, :json, default: nil
  end
end
