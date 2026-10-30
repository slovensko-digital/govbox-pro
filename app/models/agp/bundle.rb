# == Schema Information
#
# Table name: agp_bundles
#
#  id                :bigint           not null, primary key
#  bundle_identifier :uuid             not null
#  fingerprint       :string
#  status            :integer          default("init"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tenant_id         :bigint           not null
#
module Agp
  class Bundle < ApplicationRecord
    # The bundle is publicly visible in AGP (anyone with its UUID can open and sign it in the iframe), so the UUID
    # must stay random. Reopening signing of unchanged documents reuses a recent bundle found by its fingerprint.
    REUSABLE_FOR = 1.day
    # Webhooks are the primary way to learn about signatures, polling is only a fallback for lost webhooks.
    POLLING_PERIOD = 3.days
    MIN_POLLING_INTERVAL = 30.seconds
    MAX_POLLING_INTERVAL = 1.hour

    has_many :contracts, dependent: :destroy, class_name: "Agp::Contract", foreign_key: "agp_bundle_id", inverse_of: :bundle
    belongs_to :tenant

    enum :status, { "init" => 0, "init_failed" => 1, "created" => 2, "completed" => 3, "failed" => 4 }

    validates :bundle_identifier, presence: true, uniqueness: true

    before_validation :set_bundle_identifier, on: :create

    def self.find_or_create_for!(tenant:, signer_user:, message_objects:)
      contracts = message_objects.sort_by(&:id).map { |message_object| Agp::Contract.build_for(message_object, signer_user: signer_user) }
      fingerprint = fingerprint_for(tenant, signer_user, contracts)

      reusable_bundles = where(tenant: tenant, fingerprint: fingerprint, status: [:init, :init_failed, :created], created_at: REUSABLE_FOR.ago..)

      reusable_bundles.order(:created_at).last || create!(tenant: tenant, fingerprint: fingerprint, contracts: contracts)
    end

    def self.fingerprint_for(tenant, signer_user, contracts)
      parts = contracts.map do |contract|
        [contract.message_object_id, contract.message_object.name, contract.message_object.mimetype, contract.content_digest].join("/")
      end

      Digest::SHA256.hexdigest([signer_user.id, tenant.signature_settings.to_json, *parts].join("|"))
    end

    def upload!(webhook_url:, api: Agp.api_for(tenant))
      api.upload_bundle(self, webhook_url: webhook_url)
      mark_created!
    rescue Agp::Api::ConflictError
      # an earlier upload attempt reached AGP even though it did not finish for us
      mark_created!
    rescue StandardError
      update!(status: :init_failed)
      raise
    end

    def sync!(api: Agp.api_for(tenant))
      remote_bundle = api.retrieve_bundle(bundle_identifier)

      if remote_bundle
        remote_contracts = remote_bundle.fetch("contracts", []).index_by { |remote_contract| remote_contract["id"] }

        contracts.created.each do |contract|
          remote_contract = remote_contracts[contract.contract_identifier]
          next contract.failed! unless remote_contract

          signed_document = remote_contract["signed_document"]
          contract.accept_signed_document!(**api.download_signed_document(signed_document)) if signed_document.present?
        end
      else
        Rails.logger.warn("AGP bundle #{bundle_identifier} not found in AGP")
        contracts.created.each(&:failed!)
      end

      finish_if_done!
    end

    def finish_if_done!
      with_lock do
        next unless created?
        next if contracts.reload.any? { |contract| contract.init? || contract.created? }

        update!(status: contracts.all?(&:completed?) ? :completed : :failed)
      end
    end

    def expire!
      contracts.created.each(&:failed!)
      update!(status: :failed) if created?
    end

    def polling_expired?
      created_at < POLLING_PERIOD.ago
    end

    def next_polling_in
      ((Time.current - created_at) / 10).seconds.clamp(MIN_POLLING_INTERVAL, MAX_POLLING_INTERVAL)
    end

    def sync_status
      counts = contracts.group(:status).count

      {
        status: status,
        total_contracts_count: counts.values.sum,
        completed_contracts_count: counts.fetch("completed", 0),
        failed_contracts_count: counts.fetch("failed", 0),
        finished: completed? || failed?
      }
    end

    private

    def mark_created!
      transaction do
        update!(status: :created)
        contracts.each { |contract| contract.update!(status: :created) if contract.init? || contract.init_failed? }
      end

      Agp::SyncBundleJob.set(wait: MIN_POLLING_INTERVAL).perform_later(self, poll: true)
    end

    def set_bundle_identifier
      self.bundle_identifier ||= SecureRandom.uuid
    end
  end
end
