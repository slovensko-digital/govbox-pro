class UpdateDraftsTagSystemName < ActiveRecord::Migration[7.0]
  def change
    Tag.where(system_name: "Drafts").update_all(system_name: "draft")
  end
end
