module Automation
  class TagCreatedJob < ApplicationJob
    queue_as :default

    def perform(tag)
      admin_groups = tag.tenant.groups.where(group_type: "ADMIN")
      tag.groups += admin_groups
    end
  end
end
