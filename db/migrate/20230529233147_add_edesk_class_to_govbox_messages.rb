class AddEdeskClassToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :govbox_messages, :edesk_class, :string, null: false
  end
end
