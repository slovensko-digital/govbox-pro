# == Schema Information
#
# Table name: automation_rules
#
#  id                                          :integer          not null, primary key
#  name                                        :string
#  trigger_event                               :string
#  tenant_id                                   :integer          not null
#  user_id                                     :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

module Automation
  class Rule < ApplicationRecord
    belongs_to :tenant
    belongs_to :user
    has_many :conditions,
             class_name: 'Automation::Condition',
             dependent: :destroy,
             foreign_key: :automation_rule_id,
             inverse_of: :automation_rule
    has_many :actions,
             class_name: 'Automation::Action',
             dependent: :destroy,
             foreign_key: :automation_rule_id,
             inverse_of: :automation_rule
    belongs_to :rule_object, polymorphic: true

    accepts_nested_attributes_for :conditions, :actions, allow_destroy: true

    def run!(thing, _event)
      return unless conditions_met?(thing)

      actions.each { |action| action.run!(thing) }
    end

    def conditions_met?(thing)
      conditions.each { |condition| return false unless condition.satisfied?(thing) }
      true
    end
  end
end
