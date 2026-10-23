class AddContactEmailToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :contact_email, :string
  end
end
