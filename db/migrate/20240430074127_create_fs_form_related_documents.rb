class CreateFsFormRelatedDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :fs_form_related_documents do |t|
      t.references :fs_form, null: false, foreign_key: true, index: { name: :index_fs_form_template_related_documents_on_fs_form_template_id }
      t.string :data, null: false
      t.string :language, null: false
      t.string :document_type, null: false

      t.timestamps
    end

    add_index :fs_form_related_documents, [:fs_form_id, :language, :document_type], unique: true, name: 'index_fs_related_documents_on_template_id_and_language_and_type'
  end
end
