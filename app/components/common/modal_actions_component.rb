module Common
  class ModalActionsComponent < ViewComponent::Base
    renders_one :submit_button

    def initialize(toggleable: false)
      @toggleable = toggleable
    end

    def remove_content_action
      if @toggleable
        "modal#close"
      else
        "turbo-content#remove"
      end
    end
  end
end
