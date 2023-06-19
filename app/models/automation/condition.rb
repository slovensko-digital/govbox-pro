module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'

    def satisfied?(thing)
      case thing.class.name
      when 'MessageThread'
        satisfied_message_thread?(thing)
#      when 'Message'
      end
    end

    def satisfied_message_thread?(message_thread)
      case operator
      when 'contains'
        message_thread[attr].match?(value)
      end
    end
  end
end
