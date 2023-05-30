# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or find_or_create_byd alongside the database with db:setup).
#

tenant = Tenant.find_or_create_by!(name: 'Dummy Tenant')

ENV['SITE_ADMIN_EMAILS'].to_s.split(',').each.with_index(1) do |email, i|
  tenant.users.find_or_create_by!(email: email, name: "Site ADMIN User #{i}")
end

box = Box.create!(name: "Dev box", uri: "ico://sk/83300252", tenant_id: tenant.id)
Govbox::ApiConnection.create!(sub: "SPL_Irvin_83300252_KK_24022023", box_id: box.id, api_token_private_key: File.read(Rails.root + "security/govbox_api_fix.pem"))
