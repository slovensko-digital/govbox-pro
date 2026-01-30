# == Schema Information
#
# Table name: automation_conditions
#
#  id                    :bigint           not null, primary key
#  attr                  :string
#  condition_object_type :string
#  type                  :string
#  value                 :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  automation_rule_id    :bigint           not null
#  condition_object_id   :bigint
#
module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
    belongs_to :condition_object, polymorphic: true, optional: true
    before_save :cleanup_record

    attr_accessor :delete_record

    # when adding items, check defaults in condition_form_component.rb
    ATTR_LIST = %i[box sender_name recipient_name title sender_uri recipient_uri outbox attachment edesk_class fs_submission_status fs_message_type object_type api_connection type authors_api_connection].freeze

    def valid_condition_type_list_for_attr
      Automation::Condition.subclasses.map do |subclass|
        subclass.name if attr.in? subclass::VALID_ATTR_LIST
      end.compact
    end

    def box_list
      automation_rule.tenant.boxes.pluck(:name, :id)
    end

    def api_connection_list
      automation_rule.tenant.api_connections.map { |api_connection| [api_connection.name, api_connection.id] }
    end
  end

  class ValueCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[type].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing[attr] == value
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class ContainsCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[sender_name recipient_name title object_type].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing[attr]&.match?(value)
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class BooleanCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[outbox].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing[attr] == ActiveRecord::Type::Boolean.new.cast(value)
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class MetadataValueCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[sender_uri recipient_uri edesk_class fs_submission_status fs_message_type fs_submission_verification_status].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      if thing.metadata && thing.metadata[attr].is_a?(Hash)
        thing.metadata[attr] == eval(value)
      else
        thing.metadata && thing.metadata[attr]&.match?(value)
      end
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class MetadataValueNotCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[sender_uri recipient_uri edesk_class fs_submission_status fs_message_type].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing.metadata && !thing.metadata[attr]&.match?(value)
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

  class MessageMetadataValueCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = %w[edesk_class fs_message_type].freeze
    validates :attr, inclusion: { in: VALID_ATTR_LIST }

    def satisfied?(thing)
      thing.message.metadata && thing.message.metadata[attr]&.match?(value)
    end

    def cleanup_record
      self.condition_object = nil
    end
  end

  class AttachmentContentContainsCondition < Automation::Condition
    validates :value, presence: true
    VALID_ATTR_LIST = ['attachment'].freeze

    def satisfied?(thing)
      thing.objects.each do |message_object|
        return true if content_match?(message_object, value)

        message_object.nested_message_objects.each do |nested_message_object|
          return true if content_match?(nested_message_object, value)
        end
      end
      false
    end

    def cleanup_record
      self.condition_object = nil
    end

    private

    def content_match?(object, value)
      if object.pdf?
        pdf_match?(object.content, value)
      elsif object.xml?
        # TODO: fix encoding when saving content to DB
        Nokogiri::XML(object.content, nil, 'UTF-8').to_s.match?(value)
      end
    end

    def pdf_match?(object, value)
      io = StringIO.new
      io.set_encoding Encoding::BINARY
      io.write object
      pdf_string = ""
      PDF::Reader.open(io) do |pdf|
        pdf_string = pdf.pages.map(&:text).join(" ")
      end
      io.close
      pdf_string.match?(value)
    end
  end

  class ApiConnectionCondition < Automation::Condition
    validates_associated :condition_object
    VALID_ATTR_LIST = ['api_connection'].freeze

    def satisfied?(thing)
      object = if thing.respond_to? :thread
                 thing.thread
               else
                 thing
               end
      object.box.api_connection == condition_object
    end

    def cleanup_record
      self.value = nil
      self.attr = 'api_connection'
    end
  end

  class AuthorHasApiConnectionCondition < Automation::Condition
    validates_associated :condition_object
    VALID_ATTR_LIST = ['authors_api_connection'].freeze

    def satisfied?(message)
      message.box.api_connections.where(owner: message.author).any?
    end

    def cleanup_record
      self.value = nil
      self.attr = 'authors_api_connection'
    end
  end
end
