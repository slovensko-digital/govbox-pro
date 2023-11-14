class CreateNewUpvsFormTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :upvs_form_templates do |t|
      t.references :upvs_form, null: false, foreign_key: true
      t.references :tenant, null: true, foreign_key: true
      t.string :name, null: false
      t.text :template, null: false

      t.timestamps
    end
  end
end
