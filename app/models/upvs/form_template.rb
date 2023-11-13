# == Schema Information
#
# Table name: upvs_form_templates
#
#  id                                          :integer          not null, primary key
#  upvs_form_id                                :integer          not null
#  identifier                                  :string           not null
#  version                                     :string           not null
#  template                                    :text             not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Upvs::FormTemplate < ApplicationRecord
  has_one :template, class_name: 'Upvs::FormTemplate', foreign_key: 'upvs_form_id'
  has_many :related_documents, class_name: 'Upvs::FormRelatedDocument', foreign_key: 'upvs_form_id'

  def xslt_html
    related_document('CLS_F_XSLT_HTML')
  end

  def xsd_schema
    related_document('CLS_F_XSD_EDOC')
  end

  def related_document(type)
    related_documents.where(document_type: type).where("lower(language) = 'sk'")&.first&.data
  end
end
