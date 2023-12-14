class RenameUpvsFormTemplatesToUpvsForms < ActiveRecord::Migration[7.0]
  def change
    rename_table :upvs_form_templates, :upvs_forms

    remove_index :upvs_forms, name: :index_form_templates_on_identifier_and_version
  end
end
