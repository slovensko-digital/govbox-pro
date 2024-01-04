class AddApiTokenPublicKeyToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :api_token_public_key, :string
  end
end
