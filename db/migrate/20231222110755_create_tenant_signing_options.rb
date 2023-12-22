class CreateTenantSigningOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :tenant_signing_options do |t|
      t.references :tenant, null: false
      t.references :signing_setting, polymorphic: true
      t.timestamps
    end
  end
end
