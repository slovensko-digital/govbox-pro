# noinspection RubyClassVariableUsageInspection
class EventBus
  @@subscribers_map = {}

  def self.subscribe(event, subscriber)
    @@subscribers_map[event] ||= []
    @@subscribers_map[event] << subscriber
  end

  def self.subscribe_job(event, active_job_class)
    subscribe(event, ->(*args) { active_job_class.perform_later(*args) })
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
EventBus.subscribe_job :message_thread_created, Automation::MessageThreadCreatedJob
EventBus.subscribe_job :message_created, Automation::MessageCreatedJob
EventBus.subscribe :message_changed, ->(message) { Searchable::ReindexMessageThreadJob.perform_later(message.thread) }
EventBus.subscribe_job :message_thread_changed, Searchable::ReindexMessageThreadJob
EventBus.subscribe :message_thread_tag_changed,
                   ->(message_thread_tag) { Searchable::ReindexMessageThreadJob.perform_later(message_thread_tag.message_thread) }
EventBus.subscribe :tag_renamed, ->(tag) { Searchable::ReindexMessageThreadsWithTagIdJob.perform_later(tag.id) }
EventBus.subscribe :tag_removed, ->(tag) { Searchable::ReindexMessageThreadsWithTagIdJob.perform_later(tag.id) }
