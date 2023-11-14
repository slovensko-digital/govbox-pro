class RenameUpvsFormTemplatesToUpvsForms < ActiveRecord::Migration[7.0]
  def change
    rename_table :upvs_form_templates, :upvs_forms

    remove_index :upvs_forms, name: :index_form_templates_on_identifier_and_version
    add_index :upvs_forms, [:identifier, :version, :message_type], unique: true, name: :index_forms_on_identifier_version_message_type
  end
end
