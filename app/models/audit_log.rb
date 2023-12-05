# == Schema Information
#
# Table name: audit_logs
#
#  id                 :bigint           not null, primary key
#  actor_name         :string
#  changeset          :jsonb
#  happened_at        :datetime         not null
#  new_value          :string
#  previous_value     :string
#  thread_id_archived :integer
#  thread_title       :string
#  type               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  actor_id           :bigint
#  message_thread_id  :bigint
#  tenant_id          :bigint
#
require "csv"

class AuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :actor, class_name: "User"
  belongs_to :message_thread, optional: true

  class MessageThreadNoteCreated < AuditLog
    def self.create_audit_record(note)
      create_record(
        object: note,
        new_value: note.note,
        message_thread: note.message_thread
      )
    end
  end

  class MessageThreadNoteUpdated < AuditLog
    def self.create_audit_record(note)
      create_record(
        object: note,
        previous_value: note.note_previously_was,
        new_value: note.note,
        message_thread: note.message_thread
      )
    end
  end

  class MessageThreadTagCreated < AuditLog
    def self.create_audit_record(thread_tag)
      create_record(
        object: thread_tag,
        new_value: thread_tag.tag.name,
        message_thread: thread_tag.message_thread
      )
    end
  end

  class MessageThreadTagUpdated < AuditLog
    def self.create_audit_record(thread_tag)
      create_record(
        object: thread_tag,
        previous_value: thread_tag.tag.name_previously_was,
        new_value: thread_tag.tag.name,
        message_thread: thread_tag.message_thread
      )
    end
  end

  class MessageThreadTagDestroyed < AuditLog
    def self.create_audit_record(thread_tag)
      create_record(
        object: thread_tag,
        previous_value: thread_tag.tag.name,
        message_thread: thread_tag.message_thread
      )
    end
  end

  class UserLoggedIn < AuditLog
    def self.create_audit_record(user)
      create_record(object: user, tenant: user.tenant)
    end
  end

  class UserLoggedOut < AuditLog
    def self.create_audit_record(user)
      create_record(
        object: user,
        tenant: user.tenant,
        actor: user,
        actor_name: user.name
      )
    end
  end

  class FilterCreated < AuditLog
    def self.create_audit_record(filter)
      create_record(object: filter, new_value: filter.name)
    end
  end

  class FilterUpdated < AuditLog
    def self.create_audit_record(filter)
      create_record(object: filter, new_value: filter.name, previous_value: filter.name_previously_was)
    end
  end

  class FilterDestroyed < AuditLog
    def self.create_audit_record(filter)
      create_record(object: filter, previous_value: filter.name)
    end
  end

  class TagCreated < AuditLog
    def self.create_audit_record(tag)
      create_record(object: tag, new_value: tag.name)
    end
  end

  class TagUpdated < AuditLog
    def self.create_audit_record(tag)
      create_record(object: tag, new_value: tag.name, previous_value: tag.name_previously_was)
    end
  end

  class TagDestroyed < AuditLog
    def self.create_audit_record(tag)
      create_record(object: tag, previous_value: tag.name)
    end
  end

  class TagGroupCreated < AuditLog
    def self.create_audit_record(tag_group)
      create_record(object: tag_group)
    end
  end

  class TagGroupUpdated < AuditLog
    def self.create_audit_record(tag_group)
      create_record(object: tag_group)
    end
  end

  class TagGroupDestroyed < AuditLog
    def self.create_audit_record(tag_group)
      create_record(object: tag_group)
    end
  end

  class GroupCreated < AuditLog
    def self.create_audit_record(group)
      create_record(object: group, new_value: group.name)
    end
  end

  class GroupUpdated < AuditLog
    def self.create_audit_record(group)
      create_record(object: group, new_value: group.name, previous_value: group.name_previously_was)
    end
  end

  class GroupDestroyed < AuditLog
    def self.create_audit_record(group)
      create_record(object: group, previous_value: group.name)
    end
  end

  class GroupMembershipCreated < AuditLog
    def self.create_audit_record(group_membership)
      create_record(object: group_membership)
    end
  end

  class GroupMembershipUpdated < AuditLog
    def self.create_audit_record(group_membership)
      create_record(object: group_membership)
    end
  end

  class GroupMembershipDestroyed < AuditLog
    def self.create_audit_record(group_membership)
      create_record(object: group_membership)
    end
  end

  class UserCreated < AuditLog
    def self.create_audit_record(user)
      create_record(object: user, new_value: user.name)
    end
  end

  class UserUpdated < AuditLog
    def self.create_audit_record(user)
      create_record(object: user, new_value: user.name, previous_value: user.name_previously_was)
    end
  end

  class UserDestroyed < AuditLog
    def self.create_audit_record(user)
      create_record(object: user, previous_value: user.name)
    end
  end

  class AutomationRuleCreated < AuditLog
    def self.create_audit_record(automation_rule)
      create_record(object: automation_rule, new_value: automation_rule.name)
    end
  end

  class AutomationRuleUpdated < AuditLog
    def self.create_audit_record(automation_rule)
      create_record(object: automation_rule, new_value: automation_rule.name, previous_value: automation_rule.name_previously_was)
    end
  end

  class AutomationRuleDestroyed < AuditLog
    def self.create_audit_record(automation_rule)
      create_record(object: automation_rule, previous_value: automation_rule.name)
    end
  end

  # TODO: move to non-core domain
  class MessageDeliveryAuthorized < AuditLog
    def self.create_audit_record(message)
      create_record(object: message, message_thread: message.thread)
    end
  end

  class MessageDraftBeingSubmitted < AuditLog
    def self.create_audit_record(message)
      create_record(object: message, message_thread: message.thread)
    end
  end

  class MessageDraftSubmitted < AuditLog
    def self.create_audit_record(message)
      create_record(object: message, message_thread: message.thread)
    end
  end

  class MessageDraftDestroyed < AuditLog
    def self.create_audit_record(message)
      create_record(object: message, message_thread: message.thread)
    end
  end

  class MessageThreadRenamed < AuditLog
    def self.create_audit_record(message_thread)
      create_record(
        object: message_thread,
        message_thread: message_thread,
        previous_value: message_thread.title_previously_was,
        new_value: message_thread.title
      )
    end
  end

  class MessageThreadsMerged < AuditLog
    def self.create_audit_record(message_threads_collection)
      create_record(
        message_thread: message_threads_collection.first,
        object: message_threads_collection
      )
    end
  end

  class MessageObjectUpdated < AuditLog
    def self.create_audit_record(message_object)
      create_record(object: message_object, message_thread: message_object.message.message_thread)
    end
  end

  def self.create_record(object:, **args)
    create(
      tenant: Current.tenant,
      actor: Current.user,
      # TODO: SYSTEM alebo nil alebo nieco ine?
      actor_name: Current.user&.name || 'SYSTEM',
      happened_at: Time.current,
      changeset: changeset(object),
      thread_id_archived: args[:message_thread]&.id,
      thread_title: args[:message_thread]&.title,
      **args
    )
  end

  def self.changeset(object)
    if object.respond_to?(:previous_changes) && object.previous_changes.any?
      object.previous_changes
    else
      object.to_json
    end
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.find_each do |audit_record|
        csv << audit_record.attributes.values_at(*column_names)
      end
    end
  end
end
