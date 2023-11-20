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
    belongs_to :condition_object, polymorphic: true, optional: true
    before_save :cleanup_record

    attr_accessor :delete_record

    # when adding items, check defaults in condition_form_component.rb
    ATTR_LIST = %i[box sender_name recipient_name title sender_uri recipient_uri].freeze

    def valid_condition_type_list_for_attr
      Automation::Condition.subclasses.map do |subclass|
        subclass.name if attr.in? subclass::VALID_ATTR_LIST
      end.compact
    end

    def box_list
      automation_rule.tenant.boxes.pluck(:name, :id)
    end
  end

  class ContainsCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[sender_name recipient_name title].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing[attr]&.match?(value)
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class MetadataValueCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[sender_uri recipient_uri].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing.metadata && thing.metadata[attr]&.match?(value)
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class BoxCondition < Automation::Condition
    validates_associated :condition_object
    VALID_ATTR_LIST = ['box'].freeze

    def satisfied?(thing)
      object = if thing.respond_to? :thread
                 thing.thread
               else
                 thing
               end
      object.box == condition_object
    end

    def cleanup_record
      self.value = nil
      self.attr = 'box'
    end
  end
end
