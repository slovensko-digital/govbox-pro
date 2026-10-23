class Settings::UserFilterVisibilities::ListRowComponent < ViewComponent::Base
  def initialize(filter:, preference: nil)
    @filter = filter
    @preference = preference
  end

  def pinned?
    @preference&.visible? || false
  end

  def pin_path
    @preference ? helpers.settings_user_filter_visibility_path(@preference) : helpers.settings_user_filter_visibilities_path
  end

  def pin_method
    @preference ? :patch : :post
  end

  def pin_params
    if @preference
      { user_filter_visibility: { visible: !pinned? } }
    else
      { user_filter_visibility: { filter_id: @filter.id, visible: true } }
    end
  end
end
