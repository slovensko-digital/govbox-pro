class CreateSubmissions < ActiveRecord::Migration[6.1]
  def change
    create_table :submissions do |t|
      t.references :package, null: false, foreign_key: { to_table: 'submission.packages' }

      t.integer :status, null: false, default: 0
      t.boolean :form_signed, null: false
      t.boolean :form_to_be_signed, null: false
      t.string :recipient_uri, null: false
      t.string :posp_id, null: false
      t.string :posp_version, null: false
      t.string :message_type, null: false
      t.string :message_subject, null: false
      t.string :sender_business_reference
      t.string :recipient_business_reference
      t.uuid :message_id, null: false
      t.uuid :correlation_id, null: false

      t.timestamps
    end
  end
end
