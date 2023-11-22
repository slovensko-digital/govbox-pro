module Common
  class OptionsComponent < ViewComponent::Base
    renders_one :menu_content

    def initialize(id:)
      @id = id
    end
  end
end
