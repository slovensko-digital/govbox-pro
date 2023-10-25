module Common
  class AlertComponent < ViewComponent::Base
    def initialize(flash)
      @flash = flash
    end

    def notice?(type)
      type == 'notice'
    end

    def color_from_type(type)
      notice?(type) ? "green" : "red"
    end
  end
end
