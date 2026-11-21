class Api::AutomationRulesController < Api::TenantController
  before_action :set_rule, only: %i[show destroy]

  def index
    @rules = @tenant.automation_rules.includes(:conditions, actions: :action_object).order(:id)
  end

  def show; end

  def create
    @rule = @tenant.automation_rules.new(rule_attributes)

    if @rule.save
      render :show, status: :created
    else
      render_unprocessable_content(@rule.errors.full_messages.join(', '))
    end
  rescue ActiveRecord::SubclassNotFound => e
    render_unprocessable_content(e.message)
  end

  def destroy
    @rule.destroy!
    head :no_content
  end

  private

  def set_rule
    @rule = @tenant.automation_rules.find(params.expect(:id))
  end

  def rule_attributes
    permitted = params.expect(automation_rule: [:name, :trigger_event, { conditions: [%i[type attr value]], actions: [%i[type value tag]] }])

    {
      name: permitted[:name],
      trigger_event: permitted[:trigger_event],
      conditions_attributes: permitted.fetch(:conditions, []),
      actions_attributes: permitted.fetch(:actions, []).map { |action| action_attributes(action) }
    }
  end

  def action_attributes(action)
    tag_name = action.delete(:tag)
    tag_name.present? ? action.merge(action_object: find_or_build_tag(tag_name)) : action
  end

  def find_or_build_tag(name)
    @tags ||= {}
    @tags[name] ||= @tenant.tags.find_by(name: name) || @tenant.simple_tags.new(name: name)
  end
end
