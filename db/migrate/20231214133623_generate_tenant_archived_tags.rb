class GenerateTenantArchivedTags < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.create_archived_tag!(name: "Archivované", visible: true)
    end

    ArchivedTag.update_all(color: "green", icon: "fingerprint")
  end

  def down
    ArchivedTag.destroy_all
  end
end
