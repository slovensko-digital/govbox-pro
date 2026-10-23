class AddAgpModels < ActiveRecord::Migration[7.1]
  def change
    create_table :agp_bundles do |t|
      t.uuid :bundle_identifier, null: false
      t.integer :status, null: false, default: 0
      t.references :tenant, null: false, foreign_key: true
      t.timestamps

      t.index :bundle_identifier, unique: true
    end

    create_table :agp_contracts do |t|
      t.uuid :contract_identifier, null: false
      t.references :message_object, null: false, foreign_key: true
      t.datetime :message_object_updated_at, null: false
      t.references :agp_bundle, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.timestamps

      t.index :contract_identifier, unique: true
    end
  end
end
