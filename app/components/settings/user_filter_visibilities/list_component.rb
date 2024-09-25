class Settings::UserFilterVisibilities::ListComponent < ViewComponent::Base
  def initialize(visibilities)
    @visibilities = visibilities
  end
end
