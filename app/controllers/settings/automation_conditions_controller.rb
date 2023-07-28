class Settings::AutomationConditionsController < ApplicationController
  before_action :set_automation_condition, only: %i[show edit update destroy]
  before_action :set_automation_rule, only: %i[index show create edit update destroy]

  def index
    authorize Automation::Condition, policy_class: Settings::AutomationConditionPolicy
    @automation_conditions =
      policy_scope(Automation::Condition, policy_scope_class: Settings::AutomationConditionPolicy::Scope).where(
        rule: params[:automation_rule_id]
      )
  end

  def edit
    authorize @automation_condition, policy_class: Settings::AutomationConditionPolicy
  end

  def update
    authorize @automation_condition, policy_class: Settings::AutomationConditionPolicy
    if @automation_condition.update(automation_condition_params)
      #redirect_to edit_settings_automation_rule_path(@automation_rule), notice: 'Condition was successfully updated.'
      flash[:notice] = 'Condition was successfully updated.'
      render turbo_stream: turbo_stream.action(:redirect, edit_settings_automation_rule_path(@automation_rule))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @automation_condition, policy_class: Settings::AutomationConditionPolicy
    @automation_condition.destroy
    #redirect_to edit_settings_automation_rule_path(@automation_rule), notice: 'Condition was successfully deleted.'
    flash[:notice] = 'Condition was successfully updated.'
    render turbo_stream: turbo_stream.action(:redirect, edit_settings_automation_rule_path(@automation_rule))
   end

  def create
    @automation_condition = @automation_rule.conditions.new(automation_condition_params)
    authorize @automation_condition, policy_class: Settings::AutomationConditionPolicy

    if @automation_condition.save
      #redirect_to edit_settings_automation_rule_path(@automation_rule), notice: 'Condition was successfully created.'
      flash[:notice] = 'Condition was successfully updated.'
      render turbo_stream: turbo_stream.action(:redirect, edit_settings_automation_rule_path(@automation_rule))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def set_automation_condition
    @automation_condition =
      policy_scope(Automation::Condition, policy_scope_class: Settings::AutomationConditionPolicy::Scope).find(params[:id])
  end

  def set_automation_rule
    @automation_rule =
      policy_scope(Automation::Rule, policy_scope_class: Settings::AutomationRulePolicy::Scope).find(params[:automation_rule_id])
  end

  def automation_condition_params
    params.require(:automation_condition).permit(:attr, :type, :value)
  end
end
