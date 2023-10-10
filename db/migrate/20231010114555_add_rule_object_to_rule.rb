class AddRuleObjectToRule < ActiveRecord::Migration[7.0]
  def change
    change_table :automation_rules do |t|
      t.references :rule_object, polymorphic: true
    end
  end
end
