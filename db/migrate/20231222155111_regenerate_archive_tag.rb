class RegenerateArchiveTag < ActiveRecord::Migration[7.1]
  def up
    Tenant.includes(:archived_tag).find_each do |tenant|
      if tenant.archived_tag.nil?
        tenant.create_archived_tag!(name: "Archivované", color: "green", icon: "archive-box", visible: true)
      end
    end
  end

  def down
  end
end
