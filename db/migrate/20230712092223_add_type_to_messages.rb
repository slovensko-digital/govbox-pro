class AddTypeToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :type, :string

    Message.update_all(
      type: 'Message'
    )
  end
end
