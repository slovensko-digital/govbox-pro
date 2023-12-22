class CreateSigningOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :signing_options do |t|
      t.references :tenant, null: false
      t.string :type
      t.jsonb :settings

      t.timestamps
    end
  end
end
