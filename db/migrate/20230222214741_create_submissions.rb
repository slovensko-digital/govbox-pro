class CreateSubmissions < ActiveRecord::Migration[6.1]
  def change
    create_table :submissions do |t|
      t.references :package, null: false, foreign_key: { to_table: 'submission.packages' }

      t.integer :status, default: 0
      t.string :recipient_uri
      t.string :posp_id
      t.string :posp_version
      t.string :message_type
      t.string :message_subject
      t.string :package_subfolder
      t.string :sender_business_reference
      t.string :recipient_business_reference
      t.uuid :message_id
      t.uuid :correlation_id

      t.timestamps
    end
  end
end
