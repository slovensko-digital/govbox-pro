class AddUserRefToTags < ActiveRecord::Migration[7.0]
  def change
    add_reference :tags, :user, foreign_key: true
  end
end
