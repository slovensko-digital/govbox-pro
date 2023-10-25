module Common
  class AlertComponent < ViewComponent::Base
    def initialize(flash)
      @flash = flash
    end

    def is_notice(type)
      type == 'notice'
    end

    def get_color_by_type(type)
      is_notice(type) ? "green" : "red"
    end
  end
end
