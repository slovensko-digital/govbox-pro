class AddOutboxMessageLimitToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :outbox_messages_limit, :integer
  end
end
