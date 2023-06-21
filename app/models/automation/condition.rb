module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
  end

  class ContainsCondition < Automation::Condition
    def satisfied?(thing)
      thing[attr].match?(value)
    end
  end
end
