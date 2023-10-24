class UpdateRulesObjectsFromNamesToIDs < ActiveRecord::Migration[7.0]
  def change
    Automation::Action.all.each do |action|
      tag = action.automation_rule.tenant.tags.find_by(name: action.value)
      action.action_object = tag if tag
      action.save!
    end
  end
end
