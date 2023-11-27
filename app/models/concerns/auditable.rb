module Auditable
  extend ActiveSupport::Concern
  included do
    after_destroy :audit_destroy
    after_create :audit_create
    after_update :audit_update
  end
  def audit_destroy
    EventBus.publish(event_name(:destroyed), self)
  end

  def audit_create
    EventBus.publish(event_name(:created), self)
  end

  def audit_update
    EventBus.publish(event_name(:updated), self)
  end

  def event_name(action)
    "#{self.class.name.underscore.gsub("/", "_")}_#{action}".to_sym
  end
end
