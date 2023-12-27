class GenerateSignedExternallyForAllTenants < ActiveRecord::Migration[7.1]
  def up
    Tenant.find_each do |tenant|
      tenant.create_signed_externally_tag!(name: "Externe podpísané", visible: false, color: "purple", icon: "shield-check")
    end
  end

  def down
    SignedExternallyTag.destroy_all
  end
end
