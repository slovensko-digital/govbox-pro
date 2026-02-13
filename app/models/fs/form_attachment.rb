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

  def required_occurrences(xml)
    return min_occurrences, max_occurrences if form.slug != "VP_DANv24" && !identifier.in?(%w[VP_PRI_UA VP_DOK_UA])

    case identifier
    when "VP_PRI_UA"
      required_count = vp_danv24_vp_pri_ua(xml)
      return required_count, required_count
    when "VP_DOK_UA"
      required_count = vp_danv24_vp_dok_ua(xml)
      return required_count, required_count
    else
      return min_occurrences, max_occurrences
    end
  end

  private

  def vp_danv24_vp_pri_ua(xml)
    sposob_dorucenia = xml.xpath("/*:dokument/*:secPrilohyPodania/*:secPrilohaPodania/*:valSposobDoruceniaPrilohy")&.map(&:text) || []
    sposob_dorucenia.count { |it| it == "SD_ESP" }
  end

  def vp_danv24_vp_dok_ua(xml)
    sposob_dorucenia = xml.xpath("/*:dokument/*:secDokumentyPodania/*:secDokumentPodania/*:valSposobDoruceniaDokumentu")&.map(&:text) || []
    sposob_dorucenia.count { |it| it == "SD_ESP" }
  end
end
