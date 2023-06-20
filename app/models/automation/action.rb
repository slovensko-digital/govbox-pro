module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'

    def run!(thing)
      case name.to_sym
      when :add_tag
        tag = Current.tenant.tags.find_by(name: params)
        thing.tags << tag
      when :delete_tag
        tag = Current.tenant.tags.find_by(name: params)
        thing.tags.delete(tag)
      end
    end
  end
end
