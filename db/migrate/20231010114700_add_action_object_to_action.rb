class AddActionObjectToAction < ActiveRecord::Migration[7.0]
  def change
    change_table :automation_actions do |t|
      t.references :action_object, polymorphic: true
    end
  end
end
