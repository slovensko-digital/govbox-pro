class AddContactEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :contact_email, :string
  end
end
