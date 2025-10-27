module Agp
  class UploadBundleJob < ApplicationJob
    queue_as :default

    def perform(bundle, api: SigningEnvironment.signing_client.api(tenant: bundle.tenant))
      unless bundle.init?
        if bundle.created?
          bundle.contracts.each do |contract|
            contract.update(status: :created)
            Agp::PollContractStatusJob.perform_later(contract) if ENV.fetch("AGP_POLLING", "false") == "true"
          end
        end
        return
      end

      response = api.upload_bundle(bundle)
      raise "Failed to upload AGP bundle #{bundle.bundle_identifier}: #{response}" if response[:status] >= 400

      bundle.update(status: :created)
      bundle.contracts.each do |contract|
        contract.update(status: :created)
        Agp::PollContractStatusJob.perform_later(contract) if ENV.fetch("AGP_POLLING", "false") == "true"
      end
    rescue Agp::ConflictResponseError => e
      Rails.logger.info("AGP bundle #{bundle.bundle_identifier} already exists: #{e.message}")
      bundle.update(status: :created)
      bundle.contracts.each do |contract|
        contract.update(status: :created)
        Agp::PollContractStatusJob.perform_later(contract) if ENV.fetch("AGP_POLLING", "false") == "true"
      end
    rescue => e
      Rails.logger.error("Failed to upload AGP bundle #{bundle.bundle_identifier}: #{e.message}")
      bundle.update(status: :init_failed)
      raise e
    end
  end
end
