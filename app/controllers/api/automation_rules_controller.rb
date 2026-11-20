class Api::AutomationRulesController < Api::TenantController
  TRIGGER_EVENTS = %w[message_created message_updated message_draft_validated message_draft_submitted message_object_downloaded].freeze
  CONDITION_TYPES = %w[
    Automation::ContainsCondition
    Automation::ValueCondition
    Automation::BooleanCondition
    Automation::MetadataValueCondition
    Automation::MetadataValueNotCondition
    Automation::MessageMetadataValueCondition
    Automation::AttachmentContentContainsCondition
    Automation::AttachmentsPresentCondition
  ].freeze
  ACTION_TYPES = %w[Automation::AddMessageThreadTagAction Automation::UnassignMessageThreadTagAction].freeze

  def index
    @rules = @tenant.automation_rules.includes(:conditions, actions: :action_object).order(:id)
  end

  def create
    @rule = @tenant.automation_rules.new(name: rule_params.require(:name), trigger_event: rule_params.require(:trigger_event))
    raise ArgumentError, "Invalid trigger_event" unless TRIGGER_EVENTS.include?(@rule.trigger_event)

    build_conditions
    build_actions

    Automation::Rule.transaction do
      @rule.save!
    end

    render :show, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_unprocessable_content(e.message)
  end

  def destroy
    @tenant.automation_rules.find(params[:id]).destroy!
    head :no_content
  end

  private

  def rule_params
    params.require(:automation_rule)
  end

  def build_conditions
    Array(rule_params[:conditions]).each do |condition|
      type = condition[:type].to_s
      raise ArgumentError, "Invalid condition type" unless CONDITION_TYPES.include?(type)

      @rule.conditions.build(type: type, attr: condition[:attr], value: condition[:value])
    end
  end

  def build_actions
    actions = Array(rule_params[:actions])
    raise ArgumentError, "At least one action is required" if actions.empty?

    actions.each do |action|
      type = action[:type].to_s
      raise ArgumentError, "Invalid action type" unless ACTION_TYPES.include?(type)

      tag_name = action[:tag].to_s.strip
      raise ArgumentError, "Action tag is required" if tag_name.empty?

      tag = @tenant.tags.find_by(name: tag_name)
      tag ||= @tenant.simple_tags.create!(name: tag_name)
      @rule.actions.build(type: type, action_object: tag)
    end
  end
end
