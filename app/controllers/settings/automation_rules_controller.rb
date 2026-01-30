class Settings::AutomationRulesController < ApplicationController
  before_action :set_automation_rule, only: %i[edit update destroy]
  before_action :set_form_automation_rule, only: %i[header_step conditions_step actions_step create]
  before_action :transform_delete_destroy, only: %i[create update]

  def index
    authorize Automation::Rule, policy_class: Settings::AutomationRulePolicy
    @automation_rules = policy_scope(Automation::Rule, policy_scope_class: Settings::AutomationRulePolicy::Scope)
  end

  def edit
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def new
    @automation_rule = Current.tenant.automation_rules.new
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def create
    @automation_rule.tenant = Current.tenant
    @automation_rule.user = Current.user
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
    if @automation_rule.save
      redirect_to settings_automation_rules_path, notice: 'Pravidlo bolo úspešne vytvorené'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
    if @automation_rule.update(automation_rule_params)
      redirect_to settings_automation_rules_path, notice: 'Pravidlo bolo úspešne upravené'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
    @automation_rule.destroy
    redirect_to settings_automation_rules_path, notice: 'Pravidlo bolo úspešne odstránené'
  end

  def header_step
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def actions_step
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def conditions_step
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  private

  def set_automation_rule
    @automation_rule = policy_scope(Automation::Rule,
                                    policy_scope_class: Settings::AutomationRulePolicy::Scope).find(params[:id])
  end

  def set_form_automation_rule
    @automation_rule = Automation::Rule.new if automation_rule_params[:id].blank?
    @automation_rule ||= policy_scope(Automation::Rule,
                                      policy_scope_class: Settings::AutomationRulePolicy::Scope).find(automation_rule_params[:id])
    @automation_rule.assign_attributes(automation_rule_params)
  end

  def automation_rule_params
    params.require(:automation_rule).permit(
      :id,
      :name,
      :trigger_event,
      conditions_attributes: %i[_destroy id attr type value condition_object_type condition_object_id delete_record],
      actions_attributes: %i[_destroy id type value action_object_type action_object_id delete_record]
    )
  end

  # during form editing we use delete_record instead of _destroy to maintain consistent nested form, update when saving
  def transform_delete_destroy
    params.deep_transform_keys! { |key| key.match?('delete_record') ? '_destroy' : key }
  end
end
