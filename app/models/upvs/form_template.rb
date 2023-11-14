# == Schema Information
#
# Table name: upvs_form_templates
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer
#  upvs_form_id                                :integer          not null
#  name                                        :string           not null
#  template                                    :text             not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Upvs::FormTemplate < ApplicationRecord
  belongs_to :tenant, class_name: 'Tenant'
  belongs_to :form, class_name: 'Upvs::Form', foreign_key: 'upvs_form_id'
end
