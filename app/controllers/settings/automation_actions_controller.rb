class Settings::AutomationActionsController < ApplicationController
  before_action :set_automation_rule

  def create
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def edit
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def update
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def destroy
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
    @id = params[:id]
  end

  def set_automation_rule
    @automation_rule = automation_rule_params[:id].blank? ? Automation::Rule.new : Automation::Rule.find(automation_rule_params[:id]) 
    @automation_rule.assign_attributes(automation_rule_params)
    @index = params[:index].to_i
    @new_rule = Automation::Rule.new(actions: [Automation::Action.new])
  end

  def automation_rule_params
    params.require(:automation_rule).permit(
      :id, :name, :trigger_event,
      conditions_attributes: %i[id attr type value delete_record],
      actions_attributes: %i[id type value delete_record]
    )
  end
end
