class Settings::UserItemVisibilities::ListComponent < ViewComponent::Base
  def initialize(type, visibilities)
    @type = type
    @visibilities = visibilities
  end
end
