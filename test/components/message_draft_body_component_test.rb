# frozen_string_literal: true

require "test_helper"

class MessageDraftBodyComponentTest < ViewComponent::TestCase
  test "hides JS-only parts of an FS form in a draft visualization saved without that rule" do
    message = messages(:fs_accountants_draft_vp_danv24)
    message.update!(html_visualization: '<noscript><p>Pre kompletnú funkčnosť aplikácie je potrebné povoliť JavaScript</p></noscript>')

    render_inline(MessageDraftBodyComponent.new(message: message, is_last: true))

    assert_includes page.find("iframe")[:srcdoc], "<style>noscript, #buttonsPlaceholder, #statusDialog { display: none; }</style>"
  end
end
