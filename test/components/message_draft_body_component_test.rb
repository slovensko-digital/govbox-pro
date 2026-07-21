# frozen_string_literal: true

require "test_helper"

class MessageDraftBodyComponentTest < ViewComponent::TestCase
  def component
    @component ||= MessageDraftBodyComponent.new(message: nil, is_last: false)
  end

  def test_humanize_diff_maps_identifier_field_change_to_friendly_label
    diff = "3c3\n<       <ico>12345678</ico>\n---\n>       <ico>87654321</ico>"

    assert_equal ["IČO: 12345678 → 87654321"], component.humanize_diff(diff)
  end

  def test_humanize_diff_handles_namespaced_elements
    diff = "1c1\n< <ns0:dic>1020304050</ns0:dic>\n---\n> <ns0:dic>9999999999</ns0:dic>"

    assert_equal ["DIČ: 1020304050 → 9999999999"], component.humanize_diff(diff)
  end

  def test_humanize_diff_falls_back_to_raw_element_name_for_unknown_fields
    diff = "1c1\n< <nejakePole>a</nejakePole>\n---\n> <nejakePole>b</nejakePole>"

    assert_equal ["nejakePole: a → b"], component.humanize_diff(diff)
  end

  def test_humanize_diff_reports_multiple_changes
    diff = "3c3\n<   <ico>11111111</ico>\n---\n>   <ico>22222222</ico>\n" \
           "7c7\n<   <psc>81101</psc>\n---\n>   <psc>81102</psc>"

    assert_equal ["IČO: 11111111 → 22222222", "PSČ: 81101 → 81102"], component.humanize_diff(diff)
  end

  def test_humanize_diff_returns_generic_description_when_diff_is_unparseable
    assert_equal [MessageDraftBodyComponent::GENERIC_DIFF_DESCRIPTION], component.humanize_diff("garbage without diff markers")
  end

  def test_humanize_diff_returns_generic_description_for_structural_additions
    diff = "5a6,7\n>       <novaSekcia>\n>       </novaSekcia>"

    assert_equal [MessageDraftBodyComponent::GENERIC_DIFF_DESCRIPTION], component.humanize_diff(diff)
  end

  def test_humanize_diff_ignores_xml_declaration_only_change
    diff = "1c1\n< <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n---\n> <?xml version=\"1.0\" encoding=\"utf-8\"?>"

    assert_equal [MessageDraftBodyComponent::GENERIC_DIFF_DESCRIPTION], component.humanize_diff(diff)
  end
end
