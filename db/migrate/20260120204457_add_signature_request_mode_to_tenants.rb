class AddSignatureRequestModeToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :signature_request_mode, :string, default: 'signer_group', null: false
  end
end
