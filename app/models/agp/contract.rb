# == Schema Information
#
# Table name: agp_contracts
#
#  id                        :bigint           not null, primary key
#  content_digest            :string
#  contract_identifier       :uuid             not null
#  message_object_updated_at :datetime         not null
#  status                    :integer          default("init"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  agp_bundle_id             :bigint           not null
#  message_object_id         :bigint           not null
#  signer_user_id            :bigint
#
module Agp
  class Contract < ApplicationRecord
    belongs_to :bundle, class_name: "Agp::Bundle", foreign_key: "agp_bundle_id", inverse_of: :contracts
    belongs_to :message_object, class_name: "MessageObject", optional: false
    belongs_to :signer_user, class_name: "User", optional: true

    enum :status, { "init" => 0, "init_failed" => 1, "created" => 2, "completed" => 3, "failed" => 4 }

    before_validation :set_contract_identifier, on: :create

    validates :contract_identifier, presence: true, uniqueness: true
    validates :message_object_updated_at, presence: true
    validates :signer_user, presence: true, on: :create

    def self.build_for(message_object, signer_user:)
      new(
        message_object: message_object,
        message_object_updated_at: message_object.updated_at,
        content_digest: digest(message_object),
        signer_user: signer_user
      )
    end

    def self.digest(message_object)
      Digest::SHA256.hexdigest(message_object.content.to_s)
    end

    # Idempotent, webhooks and polling may deliver the same signed document concurrently.
    def accept_signed_document!(filename:, content_type:, content:)
      with_lock do
        next false unless created?

        if signer_user.nil?
          Rails.logger.warn("AGP contract #{contract_identifier} has no signer user, ignoring signed document")
          next failed!
        end

        if message_object_changed?
          Rails.logger.warn("AGP contract #{contract_identifier} was signed, but message object #{message_object_id} changed in the meantime")
          next failed!
        end

        message_object.mark_as_signed!({ name: filename, mimetype: content_type, content: Base64.strict_encode64(content) }, signer_user)
        completed!
      end
    end

    private

    # Accepting a stale signed document would overwrite newer content, e.g. a signature made meanwhile by another signer.
    def message_object_changed?
      content_digest.present? && content_digest != self.class.digest(message_object)
    end

    def set_contract_identifier
      self.contract_identifier ||= SecureRandom.uuid
    end
  end
end
