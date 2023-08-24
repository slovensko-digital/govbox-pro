# == Schema Information
#
# Table name: upvs_form_template_related_documents
#
#  id                                          :integer          not null, primary key
#  upvs_form_template_id                       :integer          not null
#  data                                        :string           not null
#  language                                    :string           not null
#  document_type                               :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Upvs::FormTemplateRelatedDocument < ApplicationRecord
  belongs_to :upvs_form_template, class_name: 'Upvs::FormTemplate'
end
