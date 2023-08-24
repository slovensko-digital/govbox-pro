class CreateUpvsFormTemplateRelatedDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :upvs_form_template_related_documents do |t|
      t.references :upvs_form_template, null: false, foreign_key: true, index: { name: :index_upvs_form_template_related_documents_on_form_template_id }
      t.string :data, null: false
      t.string :language, null: false
      t.string :document_type, null: false

      t.timestamps
    end

    add_index :upvs_form_template_related_documents, [:upvs_form_template_id, :language, :document_type], unique: true, name: 'index_related_documents_on_template_id_and_language_and_type'
  end
end
