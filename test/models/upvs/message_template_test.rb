require "test_helper"

class Upvs::MessageTemplateTest < ActiveSupport::TestCase
  XSS_PAYLOADS = [
    '<script>alert(1)</script>',
    '<img src=x onerror="alert(1)">',
    '<a href="javascript:alert(1)">klik</a>',
    '<svg onload="alert(1)"></svg>',
    '</iframe><script>alert(1)</script>'
  ].freeze

  test 'builds XML form for message draft' do
    message_template = upvs_message_templates(:general_agenda)

    message_draft = message_template.create_message(author: users(:basic), box: boxes(:ssd_main), recipient_name: 'Test OVM', recipient_uri: 'ico://sk/12345678')

    message_draft.metadata['data'] = {
      Predmet: 'Odpoved',
      Text: 'Odpoved k rozhodnutiu...'
    }
    message_draft.save

    message_template.build_message_from_template(message_draft)

    assert_equal '<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9"> <subject>Odpoved</subject> <text>Odpoved k rozhodnutiu...</text> </GeneralAgenda>', message_draft.form_object.content
  end

  test 'escapes user data in html_visualization' do
    XSS_PAYLOADS.each do |payload|
      assert_not_includes build_draft(Text: payload).html_visualization, '<', payload
    end
  end

  test 'escapes field names in html_visualization' do
    assert_not_includes build_draft('<script>alert(1)</script>' => 'hodnota').html_visualization, '<'
  end

  test 'escapes user data in PDF export document' do
    XSS_PAYLOADS.each do |payload|
      message_draft = build_draft(Text: payload)
      document = message_draft.form_object.full_html_document_from_body_content(message_draft.html_visualization)

      assert_not_includes document, payload
    end
  end

  test 'keeps plain text readable in html_visualization' do
    assert_equal 'Predmet: Odpoved, Text: Text bez znaciek', build_draft(Text: 'Text bez znaciek').html_visualization
  end

  private

  def build_draft(data)
    message_template = upvs_message_templates(:general_agenda)

    message_draft = message_template.create_message(author: users(:basic), box: boxes(:ssd_main), recipient_name: 'Test OVM', recipient_uri: 'ico://sk/12345678')
    message_draft.metadata['data'] = { Predmet: 'Odpoved' }.merge(data)
    message_draft.save

    message_template.build_message_from_template(message_draft)
    message_draft.reload
  end
end
