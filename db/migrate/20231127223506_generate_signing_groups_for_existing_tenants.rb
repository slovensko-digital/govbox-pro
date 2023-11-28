class GenerateSigningGroupsForExistingTenants < ActiveRecord::Migration[7.0]
  def up
    Tenant.find_each do |tenant|
      tenant.create_signer_group!(name: "signers")
    end
  end

  def down
    SignerGroup.destroy_all
  end
end
