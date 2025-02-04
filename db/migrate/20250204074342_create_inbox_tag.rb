class CreateInboxTag < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.create_inbox_tag!(name: "Doručené", visible: false) unless tenant.inbox_tag
      AddInboxTagToThreadsJob.set(job_context: :later).perform_later
    end
  end

  def down
    # noop
  end
end
