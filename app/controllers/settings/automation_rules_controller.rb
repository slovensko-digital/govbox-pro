class Settings::AutomationRulesController < ApplicationController
  before_action :set_automation_rule, only: %i[show edit update destroy]

  def index
    authorize Automation::Rule, policy_class: Settings::AutomationRulePolicy
    @automation_rules = policy_scope(Automation::Rule, policy_scope_class: Settings::AutomationRulePolicy::Scope)
  end

  def edit
    authorize @automation_rule, policy_class: Settings::AutomationRulePolicy
  end

  def set_automation_rule
    @automation_rule =
      policy_scope(Automation::Rule, policy_scope_class: Settings::AutomationRulePolicy::Scope).find(params[:id])
  end
end
