# == Schema Information
#
# Table name: upvs_form_template_related_documents
#
#  id                    :bigint           not null, primary key
#  data                  :string           not null
#  document_type         :string           not null
#  language              :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  upvs_form_template_id :bigint           not null
#
class Upvs::FormTemplateRelatedDocument < ApplicationRecord
  belongs_to :upvs_form_template, class_name: 'Upvs::FormTemplate'
end
