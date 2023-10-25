class UpdateRulesObjectsFromNamesToIDs < ActiveRecord::Migration[7.0]
  def change
    Automation::Action.all.each do |action|
      tag = action.automation_rule.tenant.tags.find_by(name: action.value)
      raise StandardError, "Tag #{action.value} not found, perhaps it was destroyed? Check and correct existing rules" unless tag

      action.action_object = tag
      action.save!
    end
  end
end
