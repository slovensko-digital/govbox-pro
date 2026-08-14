# frozen_string_literal: true

require "test_helper"

class Fs::FormAttachmentTest < ActiveSupport::TestCase
  test "required_occurrences returns declared occurrences for non VP_DANv24 form sharing the VP_PRI_UA group" do
    form_attachment = fs_form_attachments(:VP_REGv24)
    xml = Nokogiri::XML(<<~XML)
      <dokument>
        <secPrilohyPodania>
          <secPrilohaPodania>
            <valSposobDoruceniaPrilohy>SD_POST</valSposobDoruceniaPrilohy>
          </secPrilohaPodania>
        </secPrilohyPodania>
      </dokument>
    XML

    assert_equal [1, 99], form_attachment.required_occurrences(xml)
  end

  test "required_occurrences counts SD_ESP attachments for VP_DANv24 and VP_PRI_UA" do
    form_attachment = fs_form_attachments(:VP_DANv24_3078_781)
    xml = Nokogiri::XML(<<~XML)
      <dokument>
        <secPrilohyPodania>
          <secPrilohaPodania>
            <valSposobDoruceniaPrilohy>SD_ESP</valSposobDoruceniaPrilohy>
          </secPrilohaPodania>
          <secPrilohaPodania>
            <valSposobDoruceniaPrilohy>SD_POST</valSposobDoruceniaPrilohy>
          </secPrilohaPodania>
        </secPrilohyPodania>
      </dokument>
    XML

    assert_equal [1, 1], form_attachment.required_occurrences(xml)
  end

  test "required_occurrences returns zero occurrences for VP_DANv24 and VP_PRI_UA without SD_ESP attachments" do
    form_attachment = fs_form_attachments(:VP_DANv24_3078_781)
    xml = Nokogiri::XML("<dokument></dokument>")

    assert_equal [0, 0], form_attachment.required_occurrences(xml)
  end
end
