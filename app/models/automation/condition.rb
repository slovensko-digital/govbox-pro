module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
  end

  class ContainsCondition < Automation::Condition
    def satisfied?(thing)
      thing[attr]&.match?(value)
    end

    def type_human_string
      'obsahuje'
    end
  end

  class HasValueCondition < Automation::Condition
    def satisfied?(thing)
      thing[attr]&.has_value?(value)
    end
  end
end
