class Api::AutomationRulesController < Api::TenantController
  before_action :set_rule, only: %i[show destroy]

  rescue_from ActiveRecord::RecordInvalid do |error|
    # rescue_from runs outside of the use_en_locale around action
    render_unprocessable_content(I18n.with_locale(:en) { error.record.errors.full_messages.to_sentence })
  end
  rescue_from ActiveRecord::SubclassNotFound do |error|
    render_unprocessable_content(error.message)
  end

  def index
    @rules = @tenant.automation_rules.includes(:conditions, actions: :action_object).order(:id)
  end

  def show; end

  def create
    Automation::Rule.transaction do
      @rule = @tenant.automation_rules.create!(rule_attributes)
    end

    render :show, status: :created
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
    tag_name.present? ? action.merge(action_object: find_or_create_tag(tag_name)) : action
  end

  def find_or_create_tag(name)
    @tenant.tags.find_by(name: name) || @tenant.simple_tags.create!(name: name)
  end
end
