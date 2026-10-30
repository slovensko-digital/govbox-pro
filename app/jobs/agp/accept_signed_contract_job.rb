module Agp
  class AcceptSignedContractJob < ApplicationJob
    discard_on ActiveJob::DeserializationError

    def perform(contract_identifier)
      contract = Agp::Contract.find_by(contract_identifier: contract_identifier)
      return unless contract&.created?

      signed_document = Agp.api_for(contract.bundle.tenant).retrieve_signed_document(contract.contract_identifier)
      return unless signed_document

      contract.accept_signed_document!(**signed_document)
      contract.bundle.finish_if_done!
    end
  end
end
