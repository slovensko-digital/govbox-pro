module AuditableApiEvents
  def log_api_call(action)
    EventBus.publish(action, request, response)
  end
end
