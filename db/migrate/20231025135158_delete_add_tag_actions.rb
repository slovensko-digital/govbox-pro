class DeleteAddTagActions < ActiveRecord::Migration[7.0]
  def change
    Automation::Action.where(type: 'Automation::AddTagAction').destroy_all
  end
end
