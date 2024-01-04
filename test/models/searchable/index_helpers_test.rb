require "test_helper"

class Searchable::IndexHelpersTest < ActiveSupport::TestCase
  test "html_to_searchable_string only uses html body" do
    html = "<html><head>some junk</head><body id='test'>text</body>"

    assert_equal "text", Searchable::IndexHelpers.html_to_searchable_string(html)
  end
end
