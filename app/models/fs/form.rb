# == Schema Information
#
# Table name: fs_forms
#
#  id                         :bigint           not null, primary key
#  ez_signature               :boolean
#  group_name                 :string
#  identifier                 :string           not null
#  name                       :string           not null
#  number_identifier          :integer
#  signature_required         :boolean
#  slug                       :string
#  submission_type_identifier :string
#  subtype_name               :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class Fs::Form < ApplicationRecord
  has_many :related_documents, class_name: 'Fs::FormRelatedDocument', foreign_key: 'fs_form_id', dependent: :destroy
  has_many :attachments, class_name: 'Fs::FormAttachment', foreign_key: 'fs_form_id', dependent: :destroy

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

  def attachments_allowed?
    attachments.count == 1
  end

  def short_name(include_version: true)
    prefix = case subtype_name
             when /\Adodatočn*/i
               "DOD"
             when /\Aopravn*/i
               "OPR"
             end

    form_name = include_version ? slug: slug.sub(/v\d+$/, '')

    [prefix, form_name].compact.join("_")
  end
end
