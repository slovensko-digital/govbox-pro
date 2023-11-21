# == Schema Information
#
# Table name: upvs_form_templates
#
#  id           :bigint           not null, primary key
#  name         :string           not null
#  template     :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tenant_id    :bigint
#  upvs_form_id :bigint           not null
#
class Upvs::FormTemplate < ApplicationRecord
  belongs_to :tenant, class_name: 'Tenant'
  belongs_to :form, class_name: 'Upvs::Form', foreign_key: 'upvs_form_id'
end
