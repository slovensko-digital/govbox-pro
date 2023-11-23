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
  def self.all_institutions
    (::Upvs::ServiceWithForm.all + ::Upvs::ServiceWithFormAllowRule.all).pluck(:institution_uri, :institution_name).uniq.map { |uri, name| { uri: uri, name: name }}
  end
end
