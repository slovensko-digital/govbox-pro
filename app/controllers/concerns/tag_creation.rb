module TagCreation
  def simple_tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant
    }
  end

  def find_or_create_signing_tag(tags_scope:, user_group:, tag_name:, color:, icon:)
    tag = tags_scope.find_tag_containing_group(user_group) || tags_scope.find_or_initialize_by(
      name: tag_name
    )

    tag.name = tag_name
    tag.visible = true
    tag.groups = [user_group]
    tag.color = color
    tag.icon = icon
    tag.save!
  end
end
