class Settings::AutomationActionsController < ApplicationController
  before_action :set_automation_rule

  def create
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def edit_form
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def update
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def destroy
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
    @id = params[:id]
  end

  def rerender
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def set_automation_rule
    @automation_rule = automation_rule_params[:id].blank? ? Automation::Rule.new : Automation::Rule.find(automation_rule_params[:id])
    @automation_rule.assign_attributes(automation_rule_params)
    @index = params[:index].to_i
    @new_rule = Current.tenant.automation_rules.create(actions: [Automation::Action.new])
  end

  def automation_rule_params
    params.require(:automation_rule).permit(
      :id, :name, :trigger_event, :tenant_id,
      conditions_attributes: %i[id attr type value condition_object_type condition_object_id delete_record],
      actions_attributes: %i[id type value action_object_type action_object_id delete_record]
    )
  end
end
