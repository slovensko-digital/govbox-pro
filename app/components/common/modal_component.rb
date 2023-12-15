module Common
  class ModalComponent < ViewComponent::Base
    renders_one :header
    renders_one :modal_content

    def initialize(max_size: "max-w-lg", classes: "")
      @classes = classes
      @max_size = max_size
    end

    def remove_content_action
      "turbo-content#remove"
    end
  end
end
