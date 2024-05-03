class CreateFsForms < ActiveRecord::Migration[7.1]
  def change
    create_table :fs_forms do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :group_name
      t.string :subtype_name
      t.boolean :signature_required
      t.boolean :ez_signature
      t.string :slug
      t.integer :number_identifier

      t.timestamps
    end
  end
end
