class CreateAutomationConditions < ActiveRecord::Migration[7.0]
  def change
    create_table :automation_conditions do |t|
      t.string :attr
      t.string :operator
      t.string :value
      t.references :automation_rule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
