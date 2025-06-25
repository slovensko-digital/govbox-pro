class AddMetadataToMessageThreads < ActiveRecord::Migration[7.1]
  def change
    add_column :message_threads, :metadata, :json
  end
end
