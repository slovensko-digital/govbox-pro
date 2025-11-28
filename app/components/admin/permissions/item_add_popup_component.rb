# frozen_string_literal: true

module Admin
  module Permissions
    class ItemAddPopupComponent < ViewComponent::Base
      def initialize(title:, close_path:, items:, empty_message:, url:, item_param_key:, group_id:, item_type: :box, nested_params: false)
        super
        @title = title
        @close_path = close_path
        @items = items
        @empty_message = empty_message
        @url = url
        @item_param_key = item_param_key
        @group_id = group_id
        @item_type = item_type
        @nested_params = nested_params
      end

      def renders?
        @items.present?
      end

      def item_params(item)
        if @nested_params
          # For TagGroups: tag_group[tag_id] and tag_group[group_id]
          { "#{@item_type}_group": { @item_param_key => item.id, group_id: @group_id } }
        else
          # For BoxGroups: flat box_id and group_id
          { @item_param_key => item.id, group_id: @group_id }
        end
      end
    end
  end
end
