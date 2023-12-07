class MigrateToEverythingTag < ActiveRecord::Migration[7.0]
  def up
    Tenant.find_each do |tenant|
      tenant.admin_group.tag_groups.destroy_all

      tenant.create_everything_tag!(name: "Všetky správy", visible: false) unless tenant.everything_tag
      tenant.make_admins_see_everything!
      tenant.boxes.find_each do |box|
        box.message_threads.find_each do |thread|
          thread.tags << tenant.everything_tag
        end
      end
    end
  end

  def down
    # noop
  end
end
