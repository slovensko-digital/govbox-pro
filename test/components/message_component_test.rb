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

  test "escapes injected markup in the srcdoc attribute" do
    message = messages(:ssd_main_general_one)
    message.update!(html_visualization: '<img src=x onerror="alert(1)">')

    render_inline(MessageComponent.new(message: message, mode: :thread_view))

    assert_not_includes rendered_content, '<img src=x onerror="alert(1)">'
  end
end
