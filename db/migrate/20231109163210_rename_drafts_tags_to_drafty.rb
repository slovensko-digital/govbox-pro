class RenameDraftsTagsToDrafty < ActiveRecord::Migration[7.0]
  def up
    Tag.where(name: "Drafts").update_all(name: "Drafty")
  end
end
