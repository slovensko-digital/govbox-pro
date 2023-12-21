# == Schema Information
#
# Table name: upvs_signing_certificates
#
#  id         :bigint           not null, primary key
#  subject    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  box_id     :bigint           not null
#
class Upvs::SigningCertificate < ApplicationRecord
  belongs_to :box
end
