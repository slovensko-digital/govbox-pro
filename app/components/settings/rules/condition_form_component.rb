# frozen_string_literal: true

class Settings::Rules::ConditionFormComponent < ViewComponent::Base
  def initialize(form:, index:, enabled: true, new:)
    @form = form
    @index = index
    @enabled = enabled
    @new = new
  end

  def before_render
    @attr_list = Automation::Condition::ATTR_LIST.map { |attr| [t(attr), attr] }
    @form.object.attr ||= Automation::Condition::ATTR_LIST[0]
    @condition_type_list = @form.object.valid_condition_type_list_for_attr.map do |condition_type|
      [t(condition_type), condition_type]
    end
    @form.object.type ||= @form.object.valid_condition_type_list_for_attr.first
  end
end
