# frozen_string_literal: true

require "test_helper"

class MessageDraftSigningMultiButtonComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  test "signs with Autogram without Autogram Portal" do
    message = messages(:ssd_main_draft)

    render_inline(MessageDraftSigningMultiButtonComponent.new(message: message, signable: true))

    assert_selector "a[href='#{new_message_draft_document_selections_path(message, next_step: "sign")}']", text: /\A\s*Podpísať\s*\z/, count: 2
    assert_no_text "Podpísať Autogramom"
  end

  test "signs through Autogram Portal and keeps signing directly with Autogram in the menu" do
    message = messages(:ssd_main_draft)

    render_inline(MessageDraftSigningMultiButtonComponent.new(message: message, signable: true, agp_enabled: true))

    assert_selector "a[href='#{new_message_draft_document_selections_path(message, next_step: "sign-agp")}']", text: /\A\s*Podpísať\s*\z/
    assert_selector "a[href='#{new_message_draft_document_selections_path(message, next_step: "sign")}']", text: /\A\s*Podpísať Autogramom\s*\z/
  end
end
