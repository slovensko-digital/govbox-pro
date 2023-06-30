module Automation
  class Rule < ApplicationRecord
    belongs_to :tenant
    belongs_to :user
    has_many :conditions, class_name: 'Automation::Condition', dependent: :destroy, foreign_key: :automation_rule_id, inverse_of: :automation_rule
    has_many :actions, class_name: 'Automation::Action', dependent: :destroy, foreign_key: :automation_rule_id, inverse_of: :automation_rule

    def run!(thing, event)
      # Toto je blbost, nie? Ved uz Rule je vybrany a zavolany
      #thing.automation_rules_for_event(event).each do |rule|
        return unless conditions_met?(thing)

        actions.each do |action|
          action.run!(thing)
        end
     # end
    end

    def conditions_met?(thing)
      conditions.each do |condition|
        return false unless condition.satisfied?(thing)
      end
      true
    end
  end
end
