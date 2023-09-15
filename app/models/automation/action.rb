# == Schema Information
#
# Table name: automation_actions
#
#  id                                          :integer          not null, primary key
#  type                                        :string
#  params                                      :jsonb
#  automation_rule_id                          :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
    attr_accessor :delete_record
  end

  class AddTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: value)
      thing.tags << tag if tag && !thing.tags.include?(tag)
    end
  end

  class DeleteTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: value)
      # TODO: nemozme mazat tag, ale jeho vazbu s vecou
      # thing.tags.delete(tag) if tag
    end
  end

  class AddMessageThreadTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: value)
      thing.thread.tags << tag if tag && !thing.thread.tags.include?(tag)
    end
  end
end
