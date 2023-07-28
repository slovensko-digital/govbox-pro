class Settings::Rules::ActionFormsController < ApplicationController
  before_action :set_action_form, only: [:show]
  before_action :set_rule_form
  before_action :skip_authorization
  before_action :skip_policy_scope

  def index
    #    authorize Settings::Rules::ActionForm
    if params[:automation_rule] && (@automation_rule = Automation::Rule.find(params[:automation_rule]))
      # TODO: policy scope
      @rule_form = RuleForm.new
      @rule_form.action_forms =
        @automation_rule.actions.map do |action_form|
          new ActionForm(id: action_form.id, attr: action_form.attr, type: action_form.type, value: action_form.value)
        end
    end
  end

  def new
    @action_form = new Settings::Rules::ActionForm.new
  end

  def edit
    @action_form = @rule_form.action_forms[action_form_params[:id].to_i]
  end

  def create
    @action_form = Settings::Rules::ActionForm.new(action_form_params[:action_form])
    set_rule_form_from_json(@action_form.rule_form)
    @rule_form.action_forms << @action_form
    @action_form.id = @rule_form.action_forms.index(@action_form)
    render Settings::Rules::ActionsFormComponent.new(rule_form: @rule_form)
  end

  def show
    authorize @box, policy_class: BoxPolicy
  end

  private

  def set_rule_form
    @rule_form = Settings::Rules::RuleForm.new
    return unless action_form_params[:rule_form]

    @rule_form = Settings::Rules::RuleForm.new(action_form_params[:rule_form])
    @rule_form.action_forms.map! { |action_form| Settings::Rules::ActionForm.new(action_form) }
    @rule_form.condition_forms.map! { |condition_form| Settings::Rules::ConditionForm.new(condition_form) }
  end

  def set_rule_form_from_json(rule_form_json)
    @rule_form = Settings::Rules::RuleForm.new.from_json(rule_form_json)
    @rule_form.action_forms.map! { |action_form| Settings::Rules::ActionForm.new(action_form) }
    @rule_form.condition_forms.map! { |condition_form| Settings::Rules::ConditionForm.new(condition_form) }
  end

  def set_action_form
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end

  def action_form_params
    params.permit(:automation_rule, :id, :attr, :type, :value, rule_form: {}, action_form: %i[attr type value rule_form])
  end
end
