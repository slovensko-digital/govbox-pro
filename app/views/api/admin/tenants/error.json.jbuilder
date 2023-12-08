json.message @error ||
             @tenant.errors.full_messages[0] ||
             @admin.errors.full_messages[0] ||
             @group_membership.errors.full_messages[0]
