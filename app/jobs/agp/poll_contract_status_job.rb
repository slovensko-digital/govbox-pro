module Agp
  class PollContractStatusJob < ApplicationJob
    queue_as :default

    def perform(contract, api: SigningEnvironment.signing_client.api(tenant: contract.bundle.tenant))
      return Rails.logger.info("Skipping polling for contract #{contract.contract_identifier} with status #{contract.status}") unless contract.created?

      response = api.retrieve_contract_status(contract.contract_identifier)

      return Agp::PollContractStatusJob.set(wait: response[:headers][:retry_after].to_i.seconds).perform_later(contract) if response[:status] <= 204

      return if contract.timed_out?
      raise "Unexpected response status: #{response[:status]}" unless response[:status] == 302

      Agp::AcceptSignedContractJob.perform_later(contract.contract_identifier)
    end
  end
end
