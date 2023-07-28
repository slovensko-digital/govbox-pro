class Settings::Rules::ConditionFormsController < ApplicationController
  before_action :set_rule_form
  before_action :set_condition_form, only: [:show]
  before_action :skip_authorization
  before_action :skip_policy_scope

  def index
    #    authorize Settings::Rules::ConditionForm
    if params[:automation_rule] && (@automation_rule = Automation::Rule.find(params[:automation_rule]))
      # TODO: policy scope
      @rule_form = RuleForm.new
      @rule_form.condition_forms =
      @automation_rule.conditions.map { |condition| new ConditionForm(id: condition.id, attr: condition.attr, type: condition.type, value: condition.value) }
    end
  end

  def new
    @condition_form = new Settings::Rules::ConditionForm.new
  end

  def edit
    @condition_form = @rule_form.condition_forms[condition_form_params[:id].to_i]
  end

  def create
    @condition_form = Settings::Rules::ConditionForm.new(condition_form_params[:condition_form])
    set_rule_form_from_json(@condition_form.rule_form)
    @rule_form.condition_forms << @condition_form
    @condition_form.id = @rule_form.condition_forms.index(@condition_form)
    render Settings::Rules::ConditionsFormComponent.new(rule_form: @rule_form)
  end

  def update
    @condition_form = Settings::Rules::ConditionForm.new(condition_form_params[:condition_form])
    set_rule_form_from_json(@condition_form.rule_form)
    @rule_form.condition_forms.delete_if { |condition_form| condition_form.id.to_s == @condition_form.id.to_s }
    @rule_form.condition_forms << @condition_form
    render Settings::Rules::ConditionsFormComponent.new(rule_form: @rule_form)
  end

  def show
    authorize @box, policy_class: BoxPolicy
  end

  private

  def set_rule_form_from_json(rule_form_json)
    @rule_form = Settings::Rules::RuleForm.new.from_json(rule_form_json)
    @rule_form.action_forms.map! { |action_form| Settings::Rules::ActionForm.new(action_form) }
    @rule_form.condition_forms.map! { |condition_form| Settings::Rules::ConditionForm.new(condition_form) }
  end
  
  def set_rule_form
    @rule_form = Settings::Rules::RuleForm.new
    return unless condition_form_params[:rule_form]

    @rule_form = Settings::Rules::RuleForm.new(condition_form_params[:rule_form])
    @rule_form.action_forms.map! { |action_form| Settings::Rules::ActionForm.new(action_form) }
    @rule_form.condition_forms.map! { |condition_form| Settings::Rules::ConditionForm.new(condition_form) }
  end

  def set_condition_form
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end

  def condition_form_params
    params.permit(:automation_rule, :id, :attr, :type, :value, rule_form: {}, condition_form: %i[id attr type value rule_form])
  end
end
