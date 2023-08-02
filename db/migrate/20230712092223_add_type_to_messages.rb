class AddTypeToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :type, :string

    Message.find_each do |message|
      message.update(
        type: 'Message'
      )
    end
  end
end
