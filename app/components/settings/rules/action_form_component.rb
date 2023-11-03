class Settings::Rules::ActionFormComponent < ViewComponent::Base
  def initialize(form:, index:, new:, enabled: true)
    @form = form
    @index = index
    @enabled = enabled
    @new = new
  end

  def before_render
    @action_type_list = Automation::Action::ACTION_LIST.map { |action| [t(action), action] }
    @form.object.type ||= Automation::Action::ACTION_LIST.first
  end
end
