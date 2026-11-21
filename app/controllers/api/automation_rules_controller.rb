class Api::AutomationRulesController < Api::TenantController
  rescue_from ActiveRecord::RecordInvalid, ActiveRecord::SubclassNotFound do |error|
    render_unprocessable_content(error.message)
  end

  def index
    @rules = @tenant.automation_rules.includes(:conditions, actions: :action_object).order(:id)
  end

  def create
    @rule = @tenant.automation_rules.new(rule_params)

    Automation::Rule.transaction do
      condition_params.each { |condition| @rule.conditions.build(condition) }
      action_params.each do |action|
        @rule.actions.build(type: action[:type], action_object: find_or_create_tag(action[:tag]))
      end

      @rule.save!(context: :api)
    end

    render :show, status: :created
  end

  def destroy
    @tenant.automation_rules.find(params[:id]).destroy!
    head :no_content
  end

  private

  def rule_params
    params.require(:automation_rule).permit(:name, :trigger_event)
  end

  def condition_params
    params.require(:automation_rule).permit(conditions: %i[type attr value])[:conditions] || []
  end

  def action_params
    params.require(:automation_rule).permit(actions: %i[type tag])[:actions] || []
  end

  def find_or_create_tag(name)
    @tenant.tags.find_by(name: name) || @tenant.simple_tags.create!(name: name)
  end
end
