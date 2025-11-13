module Agp
  class AcceptSignedContractJob < ApplicationJob
    def perform(contract_id)
      contract = Agp::Contract.find_by!(contract_identifier: contract_id)
      return unless contract.created?

      message_object = contract.message_object

      agp_api = SigningEnvironment.signing_client.api(tenant: message_object.tenant)
      signed_contract = agp_api.retrieve_signed_contract(contract_id)

      message_object.mark_as_signed!(
        {
          name: signed_contract["filename"],
          mimetype: signed_contract["content_type"],
          content: signed_contract["content"]
        },
        message_object.tenant.users.first # TODO: change to real user (Current.user is not available in jobs)
      )
    end
  end
end
