class AddDraftTagToTenants < ActiveRecord::Migration[7.0]
  def change
    Tenant.all.each do |tenant|
      tenant.tags.find_or_create_by!(name: 'Drafts', external: false, visible: true)
      tenant.save!
    end
  end
end
