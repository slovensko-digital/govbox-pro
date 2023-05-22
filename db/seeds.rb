# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
@tenant = Tenant.create(name: 'slovensko.digital')
@group_all = @tenant.groups.create(name: 'All Tenant users - default system group', group_type: 'ALL')
@group_admin = @tenant.groups.create(name: 'Tenant admins - default system group', group_type: 'ADMIN')

@user = @tenant.users.create(email: 'robert.lences@gmail.com', name: 'Robo Lences', user_type: 'SITE_ADMIN')
@group_user = @user.groups.create(name: @user.name + ' group - default system group', group_type: 'USER', tenant_id: @user.tenant_id)