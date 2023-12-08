json.id @tenant.id
json.name @tenant.name
json.feature_flags @tenant.feature_flags
json.admin do
  json.id @admin.id
  json.name @admin.name
  json.email @admin.email
end
