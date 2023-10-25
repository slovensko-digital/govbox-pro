class Settings::Rules::ActionFormComponent < ViewComponent::Base
  def initialize(form:, index:, enabled: true, new:)
    @form = form
    @index = index
    @enabled = enabled
    @new = new
  end

  def before_render
    @action_type_list = Automation::Action.subclasses.map { |subclass| [t(subclass.name), subclass.name] }
    @form.object.type ||= Automation::Action.subclasses.first.name
  end
end
