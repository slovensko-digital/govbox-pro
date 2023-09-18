class Admin::Tags::VisibilityToggleComponent < ViewComponent::Base
  def initialize(tag)
    @tag = tag
    @dialog = {
      turbo_confirm: 'Naozaj zrušiť viditeľnosť štítku? Používateľom nebude zobrazovaný v zozname štítkov, a nedostanú sa k príslušným správam',
    } if @tag.visible
  end
end
