module Common
  class AlertComponent < ViewComponent::Base
    def notice?(type)
      type == 'notice'
    end
  end
end
