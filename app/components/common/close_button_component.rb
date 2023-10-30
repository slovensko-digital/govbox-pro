module Common
  class CloseButtonComponent < ViewComponent::Base
    def initialize(link_to:, target_frame: "_top")
      @link_to = link_to
      @target_frame = target_frame
    end
  end
end
