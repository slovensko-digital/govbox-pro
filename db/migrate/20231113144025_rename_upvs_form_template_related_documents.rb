class RenameUpvsFormTemplateRelatedDocuments < ActiveRecord::Migration[7.0]
  def change
    rename_table :upvs_form_template_related_documents, :upvs_form_related_documents

    rename_column :upvs_form_related_documents, :upvs_form_template_id, :upvs_form_id
    rename_index :upvs_form_related_documents, :index_upvs_form_template_related_documents_on_form_template_id, :index_upvs_form_related_documents_on_form_id

    rename_index :upvs_form_related_documents, :index_related_documents_on_template_id_and_language_and_type, :index_related_documents_on_form_id_and_language_and_type
  end
end
