module Common
  class ModalComponent < ViewComponent::Base
    renders_one :header
    renders_one :modal_content

    def initialize(max_size: "max-w-lg", classes: "", closable: true)
      @classes = classes
      @max_size = max_size
      @closable = closable
    end

    def remove_content_action
      "turbo-content#remove"
    end
  end
end
