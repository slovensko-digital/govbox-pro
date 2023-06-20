class CreateAutomationRules < ActiveRecord::Migration[7.0]
  def change
    create_table :automation_rules do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :trigger_event, null: false
      t.timestamps
    end
  end
end
