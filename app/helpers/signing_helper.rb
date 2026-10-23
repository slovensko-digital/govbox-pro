module SigningHelper
  def signer_names(users)
    safe_join(users.map { |user| content_tag(:strong, "\"#{user.name}\"") }, ", ")
  end
end
