module Common
  class ModalComponent < ViewComponent::Base
    renders_one :header
    renders_one :modal_content

    def initialize(classes = "")
      @classes = classes
    end

    def remove_content_action
      "turbo-content#remove"
    end
  end
end
