module UserAvatarHelper
  def user_avatar_src(user, sso_picture_url: nil)
    return sso_picture_url if sso_picture_url.present?

    initials_avatar(user)
  end

  private

  def initials_avatar(user)
    svg = Initials.svg(user.name, size: 34)
    encoded = Base64.strict_encode64(svg)
    "data:image/svg+xml;base64,#{encoded}"
  end
end
