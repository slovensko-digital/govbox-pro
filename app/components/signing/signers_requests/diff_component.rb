module Signing
  module SignersRequests
    class DiffComponent < ViewComponent::Base
      def initialize(diff:)
        @diff = diff
      end

      def format_users(users)
        helpers.raw(
          users.map(&:name)
               .map { |name| helpers.content_tag(:strong, "\"#{name}\"") }
               .join(", ")
        )
      end
    end
  end
end
