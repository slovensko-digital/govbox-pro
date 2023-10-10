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
    belongs_to :condition_object, polymorphic: true

    attr_accessor :delete_record

    ATTR_LIST = %i[sender_name recipient_name title sender_uri recipient_uri]
  end

  class ContainsCondition < Automation::Condition
    def satisfied?(thing)
      thing[attr]&.match?(value)
    end
  end

  class MetadataValueCondition < Automation::Condition
    def satisfied?(thing)
      thing.metadata && thing.metadata[attr]&.match?(value)
    end
  end
end
