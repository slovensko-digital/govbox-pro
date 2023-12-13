class AddUuidToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :saml_identifier, :string
  end
end
