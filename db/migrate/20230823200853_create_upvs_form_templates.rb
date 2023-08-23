class CreateUpvsFormTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :upvs_form_templates do |t|
      t.string :identifier, null: false
      t.string :version, null: false

      t.timestamps
    end

    add_index :upvs_form_templates, [:identifier, :version], unique: true, name: 'index_form_templates_on_identifier_and_version'
  end
end