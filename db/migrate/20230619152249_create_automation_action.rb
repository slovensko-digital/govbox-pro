class CreateAutomationAction < ActiveRecord::Migration[7.0]
  def change
    create_table :automation_actions do |t|
      t.string :type
      t.jsonb :params
      t.references :automation_rule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
