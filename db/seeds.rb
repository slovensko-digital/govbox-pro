# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
puts 'Type First tenant name'
tenant_name = STDIN.gets.chomp
@tenant = Tenant.create(name: tenant_name)
@group_all = @tenant.groups.create(name: 'All Tenant users - default system group', group_type: 'ALL')
@group_admin = @tenant.groups.create(name: 'Tenant admins - default system group', group_type: 'ADMIN')

puts 'Type SITE ADMIN name'
site_admin_name = STDIN.gets.chomp
puts 'Type SITE ADMIN gmail address - used for authentication'
site_admin_email = STDIN.gets.chomp
@user = @tenant.users.create(email: site_admin_email, name: site_admin_name, user_type: 'SITE_ADMIN')
@group_user = @user.groups.create(name: @user.name + ' group - default system group', group_type: 'USER', tenant_id: @user.tenant_id)