# frozen_string_literal: true

class Settings::Rules::ConditionFormComponent < ViewComponent::Base
  def initialize(form:, index:, enabled: true)
    @form = form
    @index = index
    @enabled = enabled
  end

  def before_render
    @condition_type_list = Automation::Condition.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
    @attr_list = Automation::Condition::ATTR_LIST.map { |attr| [t(attr), attr] }
  end
end
