module Admin
  module Permissions
    class ItemRowComponent < ViewComponent::Base
      def initialize(delete_path:, id: nil)
        super
        @delete_path = delete_path
        @id = id
      end
    end
  end
end
