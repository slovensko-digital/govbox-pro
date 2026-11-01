module Agp
  class BundlePolicy < ApplicationPolicy
    # The signed documents are attributed to the signer user of the contracts, so only they may sign the bundle.
    def show?
      record.tenant_id == user.tenant_id && record.contracts.where.not(signer_user_id: user.id).none?
    end

    def sync?
      show?
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
