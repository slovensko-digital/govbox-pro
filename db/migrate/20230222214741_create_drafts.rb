class CreateDrafts < ActiveRecord::Migration[7.0]
  def change
    create_table :drafts do |t|
      t.references :subject, null: false, foreign_key: true
      t.references :import, null: true, foreign_key: { to_table: :drafts_imports }

      t.integer :status, default: 0
      t.string :recipient_uri
      t.string :posp_id
      t.string :posp_version
      t.string :message_type
      t.string :message_subject
      t.string :import_subfolder
      t.string :sender_business_reference
      t.string :recipient_business_reference
      t.uuid :message_id
      t.uuid :correlation_id

      t.timestamps
    end
  end
end
