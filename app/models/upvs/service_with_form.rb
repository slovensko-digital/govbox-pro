# == Schema Information
#
# Table name: upvs_service_with_forms
#
#  id               :bigint           not null, primary key
#  institution_name :string
#  institution_uri  :string           not null
#  name             :string
#  schema_url       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Upvs::ServiceWithForm < ApplicationRecord
  scope :form_services, ->(form) { where("schema_url LIKE ?", "%#{form.metadata['posp_id']}/#{form.metadata['posp_version']}") }
end
