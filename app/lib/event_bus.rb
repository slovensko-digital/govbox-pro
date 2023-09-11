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

EventBus.subscribe_job :message_thread_changed, Searchable::ReindexMessageThreadJob
EventBus.subscribe_job :tag_renamed, Searchable::ReindexTagJob
EventBus.subscribe_job :tag_removed, Searchable::ReindexTagJob
