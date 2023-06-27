module Turbo
  class NextPageAreaComponent < ViewComponent::Base
    def initialize(id:, url:)
      @id = id
      @url = url
    end
  end
end
