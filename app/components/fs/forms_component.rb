class Fs::FormsComponent < ViewComponent::Base
  def initialize(forms_list:)
    @forms_list = forms_list
  end
end
