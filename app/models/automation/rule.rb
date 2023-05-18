module Automation
  class Rule < ApplicationRecord
    belongs_to :tenant

    attr_accessor :conditions
    attr_accessor :action

    def run!(thing)
      conditions.each do |condition|
        return unless condition.satisfied?(thing)
      end

      action.run!(thing)
    end
  end
end
