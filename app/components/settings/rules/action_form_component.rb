class Settings::Rules::ActionFormComponent < ViewComponent::Base
  def initialize(form:, index:, enabled: true)
    @form = form
    @index = index
    @enabled = enabled
  end

  def before_render
    @action_type_list = Automation::Action.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
    @form.object.type ||= @action_type_list[0][1]
  end
end
