# frozen_string_literal: true

require "test_helper"

class MessageComponentTest < ViewComponent::TestCase
  test "renders visualization iframe with sandbox that blocks scripts" do
    message = messages(:ssd_main_general_one)
    message.update!(html_visualization: '<p>Vizualizacia</p>')

    render_inline(MessageComponent.new(message: message, mode: :thread_view))

    iframe = page.find("iframe")
    sandbox = iframe[:sandbox]

    assert_not_nil sandbox, "iframe s vizualizaciou musi mat sandbox"
    assert_not_includes sandbox, "allow-scripts"
  end

  test "renders visualization iframe without inline event handlers" do
    message = messages(:ssd_main_general_one)
    message.update!(html_visualization: '<p>Vizualizacia</p>')

    render_inline(MessageComponent.new(message: message, mode: :thread_view))

    iframe = page.find("iframe")

    assert_nil iframe[:onload], "onload handler nesmie byt inline, CSP ho zablokuje"
    assert_equal "visualization-frame", iframe["data-controller"]
  end

  test "escapes injected markup of a message built from a template" do
    message = messages(:ssd_main_general_one)
    message.update!(
      html_visualization: 'Text: <img src=x onerror="alert(1)">',
      metadata: message.metadata.merge("template_id" => upvs_message_templates(:general_agenda).id)
    )

    render_inline(MessageComponent.new(message: message, mode: :thread_view))

    assert_includes page.find("iframe")[:srcdoc], '&lt;img src=x onerror=&quot;alert(1)&quot;&gt;'
  end

  test "keeps every xss payload inert in the thread view" do
    XSS_PAYLOADS.each do |payload|
      message = messages(:ssd_main_general_one)
      message.update!(
        html_visualization: "Text: #{payload}",
        metadata: message.metadata.merge("template_id" => upvs_message_templates(:general_agenda).id)
      )

      render_inline(MessageComponent.new(message: message, mode: :thread_view))

      assert_not_includes page.find("iframe")[:srcdoc], payload, "neescapovany payload v srcdoc: #{payload}"
    end
  end
  test "keeps markup of a message not built from a template" do
    message = messages(:ssd_main_general_one)
    message.update!(html_visualization: '<p>Vizualizacia</p>')

    render_inline(MessageComponent.new(message: message, mode: :thread_view))

    assert_includes page.find("iframe")[:srcdoc], '<p>Vizualizacia</p>'
  end
end
