module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'

    def satisfied?(thing)
      case operator.to_sym
      when :contains
         thing[attr].match?(value)
      end
    end
  end
end
