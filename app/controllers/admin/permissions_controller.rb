module Admin
  class PermissionsController < ApplicationController
    def index
      authorize([:admin, TagGroup])
      @groups = policy_scope([:admin, Group])
    end
  end
end
