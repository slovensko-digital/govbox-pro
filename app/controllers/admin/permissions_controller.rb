module Admin
  class PermissionsController < ApplicationController
    def index
      authorize([:admin, TagGroup])
      @groups = policy_scope([:admin, Group]).includes(:boxes, :tags, :users)
    end
  end
end
