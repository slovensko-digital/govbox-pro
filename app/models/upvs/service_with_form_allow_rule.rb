# == Schema Information
#
# Table name: upvs_service_with_form_allow_rules
#
#  id               :bigint           not null, primary key
#  institution_name :string
#  institution_uri  :string           not null
#  name             :string
#  schema_url       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Upvs::ServiceWithFormAllowRule < ApplicationRecord
  scope :form_services, ->(form) { where("schema_url LIKE ?", "%#{form.metadata['posp_id']}/#{form.metadata['posp_version']}") }

  def self.all_institutions
    (::Upvs::ServiceWithForm.all + ::Upvs::ServiceWithFormAllowRule.all).pluck(:institution_uri, :institution_name).uniq.map { |uri, name| { uri: uri, name: name }}
  end

  def self.all_institutions_with_form(form)
    (
      ::Upvs::ServiceWithForm.form_services(form) +
      ::Upvs::ServiceWithFormAllowRule.form_services(form)
    ).pluck(:institution_name, :institution_uri)
     # .uniq.map { |uri, name| { uri: uri, name: name }}
  end
end
