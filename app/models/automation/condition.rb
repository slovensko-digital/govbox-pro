# == Schema Information
#
# Table name: automation_conditions
#
#  id                                          :integer          not null, primary key
#  attr                                        :string
#  type                                        :string
#  value                                       :string
#  automation_rule_id                          :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

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

  class MetadataValueCondition < Automation::Condition
    def satisfied?(thing)
      thing.metadata && thing.metadata[attr]&.match?(value)
    end
  end
end
