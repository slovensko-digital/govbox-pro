# == Schema Information
#
# Table name: fs_form_attachments
#
#  id                          :bigint           not null, primary key
#  max_occurrences             :integer          default(99), not null
#  min_occurrences             :integer          default(0), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  fs_form_attachment_group_id :bigint           not null
#  fs_form_id                  :bigint           not null
#
class Fs::FormAttachment < ApplicationRecord
  belongs_to :form, class_name: "Fs::Form", foreign_key: "fs_form_id"
  belongs_to :group, class_name: "Fs::FormAttachmentGroup", foreign_key: "fs_form_attachment_group_id"

  delegate :identifier, :name, to: :group

  def required_count(xml: nil)
    return min_occurrences unless xml

    xml = Nokogiri::XML(xml) if xml.is_a?(String)
    return vp_danv24_vp_pri_ua(xml) if form.slug == "VP_DANv24" && identifier == "VP_PRI_UA"
    return vp_danv24_vp_dok_ua(xml) if form.slug == "VP_DANv24" && identifier == "VP_DOK_UA"

    min_occurrences
  end

  private

  def vp_danv24_vp_pri_ua(xml)
    sposob_dorucenia = xml.xpath("/*:dokument/*:secPrilohyPodania/*:secPrilohaPodania/*:valSposobDoruceniaPrilohy")&.map(&:text)
    sposob_dorucenia.count { it == "SD_ESP" }
  end

  def vp_danv24_vp_dok_ua(xml)
    sposob_dorucenia = xml.xpath("/*:dokument/*:secDokumentyPodania/*:secDokumentPodania/*:valSposobDoruceniaDokumentu")&.map(&:text)
    sposob_dorucenia.count { it == "SD_ESP" }
  end
end
