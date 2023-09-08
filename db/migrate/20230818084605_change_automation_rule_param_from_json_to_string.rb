class ChangeAutomationRuleParamFromJsonToString < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_actions, :value, :string
    Automation::Rule.all.each do |rule|
      rule.actions.each do |automation_action|
        automation_action.value = automation_action.params.values.first
        automation_action.save!
      end
    end
    remove_column :automation_actions, :params
  end
end
