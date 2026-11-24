json.id rule.id
json.name rule.name
json.trigger_event rule.trigger_event
json.conditions rule.conditions do |condition|
  json.type condition.type
  json.attr condition.attr
  json.value condition.value
end
json.actions rule.actions do |action|
  json.type action.type
  json.value action.value
  json.tag action.action_object.name if action.action_object.is_a?(Tag)
  json.webhook_id action.action_object_id if action.action_object.is_a?(Automation::Webhook)
end
