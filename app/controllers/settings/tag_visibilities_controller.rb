class Settings::TagVisibilitiesController < Settings::UserItemVisibilitiesController
  private

  def set_type
    @type = 'Tag'
  end

  def set_user_item_visibilities
    @user_item_visibilities = Current.user.build_tag_visibilities!
  end
end
