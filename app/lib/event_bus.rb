# noinspection RubyClassVariableUsageInspection
class EventBus
  @@subscribers_map = {}

  def self.subscribe(event, subscriber)
    @@subscribers_map[event] ||= []
    @@subscribers_map[event] << subscriber
  end

  def self.subscribe_job(event, active_job_class)
    subscribe(event, ->(*args) { active_job_class.perform_later(event, *args) })
  end

  def self.publish(event, *args)
    @@subscribers_map.fetch(event, []).each do |subscriber|
      subscriber.call(*args)
    end
  end

  def self.reset!
    @@subscribers_map = {}
  end
end

# reset on autoload
EventBus.reset!

# wiring

# automation
[:message_thread_created, :message_created, :message_draft_submitted, :form_object_downloaded].each do |event|
  EventBus.subscribe_job event, Automation::ApplyRulesForEventJob
end

# notifications
EventBus.subscribe :message_thread_changed, ->(thread) {
  ReindexAndNotifyFilterSubscriptionsJob.perform_later(thread.id)
}

# reindexing
EventBus.subscribe :message_draft_changed, ->(message_draft) { Searchable::ReindexMessageThreadJob.perform_later(message_draft.thread.id) }

# reindexing on removals
EventBus.subscribe :tag_renamed, ->(tag) do
  ReindexAndNotifyFilterSubscriptionsJob.perform_later_for_tag_id(tag.id)
end

EventBus.subscribe :tag_destroyed, ->(tag) do
  ReindexAndNotifyFilterSubscriptionsJob.perform_later_for_tag_id(tag.id)
end

# cleanup
EventBus.subscribe :box_destroyed, ->(box_id) { Govbox::DestroyBoxDataJob.perform_later(box_id) }

# audit logs
EventBus.subscribe :message_thread_note_created, ->(note) { AuditLog::MessageThreadNoteCreated.create_audit_record(note) }
EventBus.subscribe :message_thread_note_updated, ->(note) { AuditLog::MessageThreadNoteUpdated.create_audit_record(note) }
EventBus.subscribe :message_threads_tag_created, ->(thread_tag) { AuditLog::MessageThreadTagCreated.create_audit_record(thread_tag) }
EventBus.subscribe :message_threads_tag_updated, ->(thread_tag) { AuditLog::MessageThreadTagUpdated.create_audit_record(thread_tag) }
EventBus.subscribe :message_threads_tag_destroyed, ->(thread_tag) { AuditLog::MessageThreadTagDestroyed.create_audit_record(thread_tag) }
EventBus.subscribe :message_delivery_authorized, ->(message) { AuditLog::MessageDeliveryAuthorized.create_audit_record(message) }
EventBus.subscribe :message_draft_being_submitted, ->(message) { AuditLog::MessageDraftBeingSubmitted.create_audit_record(message) }
EventBus.subscribe :message_draft_submitted, ->(message) { AuditLog::MessageDraftSubmitted.create_audit_record(message) }
EventBus.subscribe :message_draft_destroyed, ->(message) { AuditLog::MessageDraftDestroyed.create_audit_record(message) }
EventBus.subscribe :message_thread_renamed, ->(message_thread) { AuditLog::MessageThreadRenamed.create_audit_record(message_thread) }
EventBus.subscribe :message_threads_merged, ->(message_threads_collection) { AuditLog::MessageThreadsMerged.create_audit_record(message_threads_collection) }
EventBus.subscribe :message_object_updated, ->(message_object) { AuditLog::MessageObjectUpdated.create_audit_record(message_object) }

EventBus.subscribe :user_logged_in, ->(user) { AuditLog::UserLoggedIn.create_audit_record(user) }
EventBus.subscribe :user_logged_out, ->(user) { AuditLog::UserLoggedOut.create_audit_record(user) }
EventBus.subscribe :user_created, ->(user) { AuditLog::UserCreated.create_audit_record(user) }
EventBus.subscribe :user_updated, ->(user) { AuditLog::UserUpdated.create_audit_record(user) }
EventBus.subscribe :user_destroyed, ->(user) { AuditLog::UserDestroyed.create_audit_record(user) }
EventBus.subscribe :group_created, ->(group) { AuditLog::GroupCreated.create_audit_record(group) }
EventBus.subscribe :group_updated, ->(group) { AuditLog::GroupUpdated.create_audit_record(group) }
EventBus.subscribe :group_destroyed, ->(group) { AuditLog::GroupDestroyed.create_audit_record(group) }
EventBus.subscribe :group_membership_created, ->(group_membership) { AuditLog::GroupMembershipCreated.create_audit_record(group_membership) }
EventBus.subscribe :group_membership_updated, ->(group_membership) { AuditLog::GroupMembershipUpdated.create_audit_record(group_membership) }
EventBus.subscribe :group_membership_destroyed, ->(group_membership) { AuditLog::GroupMembershipDestroyed.create_audit_record(group_membership) }
EventBus.subscribe :tag_created, ->(tag) { AuditLog::TagCreated.create_audit_record(tag) }
EventBus.subscribe :tag_updated, ->(tag) { AuditLog::TagUpdated.create_audit_record(tag) }
EventBus.subscribe :tag_destroyed, ->(tag) { AuditLog::TagDestroyed.create_audit_record(tag) }
EventBus.subscribe :tag_group_created, ->(tag_group) { AuditLog::TagGroupCreated.create_audit_record(tag_group) }
EventBus.subscribe :tag_group_updated, ->(tag_group) { AuditLog::TagGroupUpdated.create_audit_record(tag_group) }
EventBus.subscribe :tag_group_destroyed, ->(tag_group) { AuditLog::TagGroupDestroyed.create_audit_record(tag_group) }
EventBus.subscribe :automation_rule_created, ->(automation_rule) { AuditLog::AutomationRuleCreated.create_audit_record(automation_rule) }
EventBus.subscribe :automation_rule_updated, ->(automation_rule) { AuditLog::AutomationRuleUpdated.create_audit_record(automation_rule) }
EventBus.subscribe :automation_rule_destroyed, ->(automation_rule) { AuditLog::AutomationRuleDestroyed.create_audit_record(automation_rule) }
EventBus.subscribe :filter_created, ->(filter) { AuditLog::FilterCreated.create_audit_record(filter) }
EventBus.subscribe :filter_updated, ->(filter) { AuditLog::FilterUpdated.create_audit_record(filter) }
EventBus.subscribe :filter_destroyed, ->(filter) { AuditLog::FilterDestroyed.create_audit_record(filter) }
EventBus.subscribe :box_sync_requested, ->(box) { AuditLog::BoxSyncRequested.create_audit_record(box) }
EventBus.subscribe :box_sync_all_requested, -> { AuditLog::BoxSyncAllRequested.create_audit_record }
