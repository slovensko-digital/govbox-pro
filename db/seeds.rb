# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or find_or_create_byd alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.find_or_create_by([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.find_or_create_by(name: 'Luke', movie: movies.first)

tenant = Tenant.find_or_create_by!(name: 'Dummy Tenant')

ENV['SITE_ADMIN_EMAILS'].to_s.split(',').each.with_index(1) do |email, i|
  tenant.users.find_or_create_by!(email: email, name: "Site ADMIN User #{i}")
end
