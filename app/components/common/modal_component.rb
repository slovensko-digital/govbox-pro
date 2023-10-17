module Common
  class ModalComponent < ViewComponent::Base
    renders_one :button
    renders_one :header
    renders_one :modal_content
  end
end
