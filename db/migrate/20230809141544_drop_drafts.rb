class DropDrafts < ActiveRecord::Migration[7.0]
  def up
    drop_table :drafts_objects
    drop_table :drafts
  end
end
