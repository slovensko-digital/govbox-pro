module Common
  class AlertComponent < ViewComponent::Base
    def initialize(flash)
      @flash = flash
    end

    def notice?(type)
      type == 'notice'
    end
  end
end
