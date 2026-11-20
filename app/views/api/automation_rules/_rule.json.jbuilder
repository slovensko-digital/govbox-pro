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
  json.tag action.action_object&.name
end
