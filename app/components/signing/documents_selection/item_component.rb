module Signing
  module DocumentsSelection
    class ItemComponent < ViewComponent::Base
      def initialize(message_object:, name: nil, icon:, checked_ids: [])
        @message_object = message_object
        @name = name || MessageObjectHelper.displayable_name(message_object)
        @icon = icon
        @checked = checked_ids.include?(message_object.id.to_s)
      end
    end
  end
end
