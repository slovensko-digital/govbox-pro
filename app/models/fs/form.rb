# == Schema Information
#
# Table name: fs_forms
#
#  id                         :integer          not null, primary key
#  identifier                 :string           not null
#  name                       :string           not null
#  group_name                 :string
#  subtype_name               :string
#  signature_required         :boolean
#  ez_signature               :boolean
#  slug                       :string
#  number_identifier          :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  submission_type_identifier :string
#

class Fs::Form < ApplicationRecord
  has_many :related_documents, class_name: 'Fs::FormRelatedDocument', foreign_key: 'fs_form_id', dependent: :destroy

  def xslt_html
    related_document('CLS_F_XSLT_HTML')
  end

  def xslt_txt
    related_document('CLS_F_XSLT_TXT_SGN')
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
