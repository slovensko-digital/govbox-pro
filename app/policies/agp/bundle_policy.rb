module Agp
  class BundlePolicy < ApplicationPolicy
    # TODO: revise policies

    def show?
      record.tenant_id == user.tenant_id
    end

    def create?
      true
    end

    def new?
      true
    end

    class Scope < Scope
      def resolve
        scope.where(tenant: user.tenant)
      end
    end
  end
end
