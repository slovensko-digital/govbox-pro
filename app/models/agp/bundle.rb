# == Schema Information
#
# Table name: agp_bundles
#
#  id                :bigint           not null, primary key
#  bundle_identifier :uuid             not null
#  status            :integer          default("init"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tenant_id         :bigint           not null
#
module Agp
  class Bundle < ApplicationRecord
    has_many :contracts, dependent: :destroy, class_name: "Agp::Contract", foreign_key: "agp_bundle_id", inverse_of: :bundle
    belongs_to :tenant
    enum status: { "init" => 0, "init_failed" => 1, "created" => 2, "completed" => 3, "failed" => 4 }
    validates :bundle_identifier, presence: true, uniqueness: true

    accepts_nested_attributes_for :contracts

    def self.find_or_initialize_from_message_objects(tenant, message_objects)
      uuid = generate_uuid_from_message_objects(message_objects)
      bundle = find_or_initialize_by(bundle_identifier: uuid)
      raise "Different tenant" if bundle.tenant && bundle.tenant != tenant

      bundle.contracts = message_objects.map do |mo|
        Agp::Contract.new(
          message_object: mo,
          message_object_updated_at: mo.updated_at,
          contract_identifier: SecureRandom.uuid
        )
      end

      bundle
    end

    def self.generate_uuid_from_message_objects(message_objects)
      digest_input = message_objects.map { |mo| "#{mo.id}#{mo.updated_at}" }.sort.join
      digest = Digest::SHA256.hexdigest(digest_input)
      "#{digest[0..7]}-#{digest[8..11]}-#{digest[12..15]}-#{digest[16..19]}-#{digest[20..31]}"
    end
  end
end
