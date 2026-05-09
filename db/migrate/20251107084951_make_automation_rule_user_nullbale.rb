class MakeAutomationRuleUserNullbale < ActiveRecord::Migration[7.1]
  def change
    change_column_null :automation_rules, :user_id, true
  end
end
