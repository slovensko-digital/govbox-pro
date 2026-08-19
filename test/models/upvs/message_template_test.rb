require "test_helper"

class Upvs::MessageTemplateTest < ActiveSupport::TestCase
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

  test 'escapes template data in PDF export document' do
    ['<script>alert(1)</script>', '<img src=x onerror="alert(1)">', '<svg onload="alert(1)"></svg>', '</iframe><script>alert(1)</script>'].each do |payload|
      assert_not_includes pdf_document_for(build_draft(Text: payload)), payload
    end
  end

  test 'keeps markup of a message not built from a template in PDF export document' do
    message_draft = build_draft(Text: 'Text bez znaciek')
    message_draft.update!(html_visualization: '<p>Vizualizacia</p>', metadata: message_draft.metadata.except('template_id'))

    assert_includes pdf_document_for(message_draft), '<p>Vizualizacia</p>'
  end

  test 'keeps plain text readable in html_visualization' do
    assert_equal 'Predmet: Odpoved, Text: Text bez znaciek', build_draft(Text: 'Text bez znaciek').html_visualization
  end

  private

  def pdf_document_for(message_draft)
    document = nil
    grover = Struct.new(:to_pdf).new('%PDF')

    Grover.stub(:new, ->(html, **_options) { document = html; grover }) do
      message_draft.form_object.prepare_pdf_visualization_from_html
    end

    document
  end

  def build_draft(data)
    message_template = upvs_message_templates(:general_agenda)

    message_draft = message_template.create_message(author: users(:basic), box: boxes(:ssd_main), recipient_name: 'Test OVM', recipient_uri: 'ico://sk/12345678')
    message_draft.metadata['data'] = { Predmet: 'Odpoved' }.merge(data)
    message_draft.save

    message_template.build_message_from_template(message_draft)
    message_draft.reload
  end
end
