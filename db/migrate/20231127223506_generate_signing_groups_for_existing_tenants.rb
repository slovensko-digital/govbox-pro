class GenerateSigningGroupsForExistingTenants < ActiveRecord::Migration[7.0]
  def up
    Tenant.find_each do |tenant|
      tenant.create_signer_group!(name: 'Podpisovatelia')
    end
  end

  def down
    GroupSigner.destroy_all
  end
end
