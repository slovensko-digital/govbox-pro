class CreateAutomationWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :automation_webhooks do |t|
      t.references :tenant, null: false
      t.string :name, null: false
      t.string :url, null: false

      t.timestamps
    end

    add_foreign_key :automation_webhooks, :tenants, on_delete: :cascade
  end
end
