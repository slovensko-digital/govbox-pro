class TW::CreateFilterComponent < ViewComponent::Base
  def initialize(filter:)
    @filter = filter
  end
end
