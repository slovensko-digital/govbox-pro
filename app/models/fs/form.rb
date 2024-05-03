# == Schema Information
#
# Table name: fs_forms
#
#  id                 :bigint           not null, primary key
#  ez_signature       :boolean
#  group_name         :string
#  identifier         :string           not null
#  name               :string           not null
#  number_identifier  :integer
#  signature_required :boolean
#  slug               :string
#  subtype_name       :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Fs::Form < ApplicationRecord
  has_many :related_documents, class_name: 'Fs::FormRelatedDocument', foreign_key: 'fs_form_id', dependent: :destroy

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
