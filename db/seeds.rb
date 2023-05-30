# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Temporary seed
Tenant.create!(name: "Dev tenant")
User.create!(email: "lucia.janikova@slovensko.digital", name: "Lucia", tenant_id: 1)
User.create!(email: "rober.lences@gmail.com", name: "Robo", tenant_id: 1)
Box.create!(name: "Dev box", uri: "ico://sk/83300252", tenant_id: 1)
Govbox::ApiConnection.create!(sub: "SPL_Irvin_83300252_KK_24022023", box_id: 1, api_token_private_key: File.read(Rails.root + "security/govbox_api_fix.pem"))
