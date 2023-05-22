/*
 delete from group_memberships;
 delete from users;
 delete from groups;
 delete from tenants;
 */
update users
set user_type = 'SITE_ADMIN'
where email like 'rober%'