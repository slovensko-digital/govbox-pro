class CreateAutomationWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_enum :request_type, %w[plain standard]
    create_enum :auth_type, %w[hmac ed25519 jwt basic]

    create_table :automation_webhooks do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :request_type, enum_type: 'request_type', null: false
      t.string :secret
      t.string :auth, enum_type: 'auth_type'

      t.timestamps

      t.references :tenant, null: false, foreign_key: true
    end
  end
end
