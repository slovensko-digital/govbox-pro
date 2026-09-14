# frozen_string_literal: true

require "test_helper"

class NestedMessageObjectTest < ActiveSupport::TestCase
  test "downloadable_as_pdf? resolves the fs_pdf_visualization feature flag through the message tenant" do
    message_object = message_objects(:fs_accountants_dphv21_form)
    message_object.message.form.update!(pdf_supported: true)
    nested = message_object.nested_message_objects.create!(
      name: "nested.xml", mimetype: "application/xml", content: "<dokument/>"
    )

    assert_not nested.downloadable_as_pdf?

    nested.message.tenant.enable_feature(:fs_pdf_visualization, force: true)
    assert nested.downloadable_as_pdf?
  end
end
