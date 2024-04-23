# == Schema Information
#
# Table name: upvs_forms
#
#  id           :bigint           not null, primary key
#  identifier   :string           not null
#  message_type :string           not null
#  version      :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Upvs::Form < ApplicationRecord
  has_many :related_documents, class_name: 'Upvs::FormRelatedDocument', foreign_key: 'upvs_form_id'

  def xslt_html
    related_document('CLS_F_XSLT_HTML')
  end

  def xsl_fo
    related_document('CLS_F_XSL_FO')
  end

  def xsd_schema
    related_document('CLS_F_XSD_EDOC')
  end

  def related_document(type)
    related_documents.where(document_type: type).where("lower(language) = 'sk'")&.first&.data
  end
end
