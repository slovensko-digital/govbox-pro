class CreateUpvsServiceWithFormAllowRules < ActiveRecord::Migration[7.0]
  def change
    create_table :upvs_service_with_form_allow_rules do |t|
      t.string :name
      t.string :institution_uri, null: false
      t.string :institution_name
      t.string :schema_url
      t.string :type

      t.timestamps
    end
  end
end
