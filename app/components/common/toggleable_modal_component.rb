module Common
  class ToggleableModalComponent < ViewComponent::Base
    renders_one :button
    renders_one :header
    renders_one :modal_content
  end
end
