# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or find_or_create_byd alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.find_or_create_by([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.find_or_create_by(name: 'Luke', movie: movies.first)

# TODO - upratat, aby sa nic nepytalo
puts 'Type First tenant name'
tenant_name = STDIN.gets.chomp
@tenant = Tenant.find_or_create_by!(name: tenant_name)

puts 'Type ADMIN name'
site_admin_name = STDIN.gets.chomp
puts 'Type ADMIN gmail address - used for authentication'
site_admin_email = STDIN.gets.chomp
@user = @tenant.users.find_or_create_by!(email: site_admin_email, name: site_admin_name)

