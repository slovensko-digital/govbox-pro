class Agp::AcceptSignedContractJob < ApplicationJob
  def perform(contract_id)
    contract = Agp::Contract.find_by!(contract_identifier: contract_id)
    message_object = contract.message_object

    agp_api = SigningEnvironment.signing_client.api(tenant: message_object.tenant)
    signed_contract = agp_api.retrieve_signed_contract(contract_id)

    Rails.logger.debug("AGP signed contract retrieval result: #{signed_contract}")

    message_object.mark_message_object_as_signed(
      {
        name: signed_contract["filename"],
        mimetype: signed_contract["content_type"],
        content: signed_contract["content"]
      },
      message_object.tenant.users.first # TODO: change to real user (Current.user is not available in jobs)
    )
  end
end
