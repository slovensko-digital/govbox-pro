# == Schema Information
#
# Table name: upvs_service_with_form_allow_rules
#
#  id               :integer          not null, primary key
#  name             :string
#  institution_uri  :string           not null
#  institution_name :string
#  schema_url       :string
#  type             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Upvs::ServiceWithForm < Upvs::ServiceWithFormAllowRule
end
