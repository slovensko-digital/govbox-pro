class AddFingerprintAndContentDigestToAgp < ActiveRecord::Migration[8.1]
  def change
    add_column :agp_bundles, :fingerprint, :string
    add_index :agp_bundles, [:tenant_id, :fingerprint]

    add_column :agp_contracts, :content_digest, :string
  end
end
