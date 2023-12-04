class GenerateTenantSigningTags < ActiveRecord::Migration[7.0]
  def up
    Tenant.find_each do |tenant|
      tenant.create_signature_requested_tag!(name: "Na podpis", visible: true)
      tenant.create_signed_tag!(name: "Podpísané", visible: true)
    end
  end

  def down
    SignatureRequestedTag.destroy_all
    SignedTag.destroy_all
  end
end
