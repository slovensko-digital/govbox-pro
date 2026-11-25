class Api::AutomationRulesController < Api::TenantController
  before_action :set_rule, only: %i[show destroy]

  def index
    @rules = @tenant.automation_rules.includes(:conditions, actions: :action_object).order(:id)
  end

  def show; end

  def create
    Automation::Rule.transaction do
      @rule = @tenant.automation_rules.new(rule_attributes)

      if @rule.save
        render :show, status: :created
      else
        render_unprocessable_content(@rule.errors.full_messages.join(', '))
        raise ActiveRecord::Rollback
      end
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
    permitted = params.expect(automation_rule: [:name, :trigger_event, { conditions: [%i[type attr value]], actions: [%i[type value tag webhook_id]] }])

    {
      name: permitted[:name],
      trigger_event: permitted[:trigger_event],
      conditions_attributes: permitted.fetch(:conditions, []),
      actions_attributes: permitted.fetch(:actions, []).map { |action| action_attributes(action) }
    }
  end

  def action_attributes(action)
    tag_name = action.delete(:tag)
    webhook_id = action.delete(:webhook_id)
    raise ArgumentError, "Action cannot have both tag and webhook_id" if tag_name.present? && webhook_id.present?

    if tag_name.present?
      action.merge(action_object: @tenant.simple_tags.find_or_create_by(name: tag_name))
    elsif webhook_id.present?
      action.merge(action_object: @tenant.automation_webhooks.find_by(id: webhook_id))
    else
      action
    end
  end
end
