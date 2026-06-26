class AddIsSiteAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_site_admin, :boolean, default: false, null: false

    site_admin_emails = ENV['SITE_ADMIN_EMAILS'].to_s.split(',')
    User.where(email: site_admin_emails).update_all(is_site_admin: true)
  end
end
