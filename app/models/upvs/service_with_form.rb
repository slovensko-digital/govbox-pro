# == Schema Information
#
# Table name: upvs_service_with_forms
#
#  id               :bigint           not null, primary key
#  changed_at       :datetime
#  external_code    :string
#  info_url         :string
#  institution_name :string
#  institution_uri  :string           not null
#  meta_is_code     :string
#  name             :string
#  schema_url       :string
#  type             :string
#  url              :string
#  valid_from       :datetime
#  valid_to         :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  instance_id      :integer          not null
#

class Upvs::ServiceWithForm < ApplicationRecord
end
