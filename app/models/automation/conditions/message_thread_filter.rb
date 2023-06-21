module Automation
  module Conditions
    class MessageThreadFilter
      def initialize(**filters)
        @filters = filters
      end

      def satisfied?(message_thread)
        return false if @filters[:title] && !@filters[:title].match?(message_thread.title)

        # TODO others

        true
      end
    end
  end
end
