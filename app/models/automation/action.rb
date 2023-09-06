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
  end

  class AddTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: params['tag_name'])
      thing.tags << tag if tag && !thing.tags.include?(tag)
    end

    def type_human_string
      'Pridaj štítok'
    end
  end

  class DeleteTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: params['tag_name'])
      # TODO: nemozme mazat tag, ale jeho vazbu s vecou
      # thing.tags.delete(tag) if tag
    end

    def type_human_string
      'Odober štítok'
    end
  end

  class AddMessageThreadTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: params['tag_name'])
      thing.thread.tags << tag if tag && !thing.thread.tags.include?(tag)
    end
  end
end
