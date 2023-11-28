module Common
  class InlineRenameComponent < ViewComponent::Base
    def initialize(name:, model:, url: nil, method: :patch, field: :name)
      @name = name
      @model = model
      @url = url ? url : model
      @method = @method
      @field = field
    end
  end
end
