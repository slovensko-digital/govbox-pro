class CreateFsForms < ActiveRecord::Migration[7.1]
  def change
    create_table :fs_forms do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :subtype_name
      t.integer :submission_type_id
      t.integer :object_type_id
      t.string :xdc_identifier
      t.boolean :signature_required
      t.boolean :ez_signature
      t.string :group_slug
      t.integer :group_number_id

      t.timestamps
    end
  end
end
