module TagCreation
  def simple_tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant
    }
  end
end
