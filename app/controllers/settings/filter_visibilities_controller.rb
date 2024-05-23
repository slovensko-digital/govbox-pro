class Settings::FilterVisibilitiesController < Settings::UserItemVisibilitiesController
  private

  def set_type
    @type = 'Filter'
  end

  def set_user_item_visibilities
    @user_item_visibilities = Current.user.build_filter_visibilities!
  end
end
