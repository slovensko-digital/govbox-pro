# == Schema Information
#
# Table name: upvs_service_with_forms
#
#  id                                          :integer          not null, primary key
#  instance_id                                 :integer          not null
#  external_code                               :integer
#  meta_is_code                                :integer
#  name                                        :string
#  type                                        :string
#  institution_uri                             :string           not null
#  institution_name                            :string
#  valid_from                                  :datetime
#  valid_to                                    :datetime
#  url                                         :string
#  info_url                                    :string
#  schema_url                                  :string
#  changed_at                                  :datetime
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Upvs::ServiceWithForm < ApplicationRecord
end
