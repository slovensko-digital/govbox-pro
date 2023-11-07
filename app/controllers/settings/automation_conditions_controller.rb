class Settings::AutomationConditionsController < ApplicationController
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
  end

  def rerender
    @index = params[:automation_condition_index].to_i
    @new = (params[:new] == 'true')
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def set_automation_rule
    @automation_rule = Current.tenant.automation_rules.new(automation_rule_params)
    @index = params[:index].to_i
    @new_rule = Current.tenant.automation_rules.new(conditions: [Automation::Condition.new])
  end

  def automation_rule_params
    params.require(:automation_rule).permit(
      :id, :name, :trigger_event,
      conditions_attributes: %i[id attr type value condition_object_type condition_object_id delete_record],
      actions_attributes: %i[id type value action_object_type action_object_id delete_record]
    )
  end
end
