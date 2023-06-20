module Automate
  def run_rules_for(thing, event, params: {})
    # TODO - prasacina? Potrebujem kvoli spravnemu urceniu tenanta. Asi najkrajsie hodit aj do message modelu vazbu na tenanta cez thread
    case thing.class.name
    when 'Message'
      thing.thread.tenant.automation_rules.where(trigger_event: event).each do |rule|
        rule.run!(thing, event)
      end
    when 'MessageThread'
      thing.tenant.automation_rules.where(trigger_event: event).each do |rule|
        rule.run!(thing, event)
      end
    end
  end
end
