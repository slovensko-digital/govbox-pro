class CreateSignerGroupSigningTags < ActiveRecord::Migration[7.1]
  def change
    Tenant.find_each do |tenant|
      tenant.signer_group.create_signature_requested_tag!
    end
  end
end
