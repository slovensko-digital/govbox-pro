module Automation
  class Action < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'
  end

  class AddTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: params['tag_name'])
      thing.tags << tag if tag
    end

    def type_human_string
      'Pridaj štítok'
    end
  end

  class DeleteTagAction < Automation::Action
    def run!(thing)
      tag = thing.tenant.tags.find_by(name: params['tag_name'])
      thing.tags.delete(tag) if tag
    end

    def type_human_string
      'Odober štítok'
    end
  end
end
