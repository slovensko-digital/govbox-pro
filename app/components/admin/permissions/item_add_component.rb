module Admin
  module Permissions
    class ItemAddComponent < ViewComponent::Base
      def initialize(url:, params: {}, classes: nil)
        super
        @url = url
        @params = params
        @classes = classes
      end
    end
  end
end
