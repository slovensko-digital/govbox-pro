module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'

    def run!(thing)
      case name.to_sym
      when :add_tag
        tag = Tag.find_by(name: params[:name])
        thing.tags.delete(tag)
      when :delete_tag
        tag = Tag.find_by(name: params[:name])
        thing.tags << tag
      end
    end
  end
end
