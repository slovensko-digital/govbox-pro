# == Schema Information
#
# Table name: agp_contracts
#
#  id                        :bigint           not null, primary key
#  contract_identifier       :uuid             not null
#  message_object_updated_at :datetime         not null
#  status                    :integer          default("init"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  agp_bundle_id             :bigint           not null
#  message_object_id         :bigint           not null
#
class Agp::Contract < ApplicationRecord
  belongs_to :bundle, class_name: "Agp::Bundle", foreign_key: "agp_bundle_id", inverse_of: :contracts
  belongs_to :message_object, class_name: "MessageObject", optional: false

  enum status: ["init", "init_failed", "created", "completed", "failed"]

  before_validation :set_contract_identifier, on: :create

  validates :contract_identifier, presence: true, uniqueness: true
  validates :message_object_updated_at, presence: true

  private

  def set_contract_identifier
    self.contract_identifier ||= SecureRandom.uuid
  end
end
