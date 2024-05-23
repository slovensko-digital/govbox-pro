# == Schema Information
#
# Table name: upvs_service_with_form_allow_rules
#
#  id               :bigint           not null, primary key
#  institution_name :string
#  institution_uri  :string           not null
#  name             :string
#  schema_url       :string
#  type             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Upvs::ServiceWithFormAllowRule < ApplicationRecord
  scope :matching_metadata, ->(metadata) { where("schema_url LIKE ?", "%#{metadata['posp_id']}/#{metadata['posp_version']}").or(where("schema_url LIKE ?", "%#{metadata['posp_id']}/*")) }

  def self.all_institutions_with_template_support(template)
    ::Upvs::ServiceWithFormAllowRule.matching_metadata(template.metadata)
  end
end
