require "test_helper"

class Searchable::IndexHelpersTest < ActiveSupport::TestCase
  test "html_to_searchable_string only uses html body" do
    html = "<html><head>some junk</head><body id='test'>text</body>"

    assert_equal "text", Searchable::IndexHelpers.html_to_searchable_string(html)
  end

  test "does not index head script and style when body is present" do
    html = <<~HTML
      <html>
        <head>
          <style>.hidden { display:none; }</style>
          <script>var tokenFromHead = 'SHOULD_NOT_BE_INDEXED';</script>
        </head>
        <body>
          Visible content only
        </body>
      </html>
    HTML

    result = Searchable::IndexHelpers.html_to_searchable_string(html)

    assert_equal "Visible content only", result
    assert_not_includes result, "SHOULD_NOT_BE_INDEXED"
  end

  test "does not index script and style text when body is missing" do
    html = <<~HTML
      <html>
        <head>
          <style>.hidden { display:none; }</style>
          <script>var tokenFromScript = 'INDEXED_WHEN_BODY_MISSING';</script>
        </head>
        <div>Visible content only</div>
      </html>
    HTML

    result = Searchable::IndexHelpers.html_to_searchable_string(html)

    assert_not_includes result, "INDEXED_WHEN_BODY_MISSING"
    assert_not_includes result, ".hidden"
    assert_includes result, "Visible content only"
  end

  test "indexes namespaced body content without head script payload" do
    html = <<~HTML
      <html>
        <head>
          <script>var namespacedBodyToken = 'INDEXED_WITH_NAMESPACED_BODY';</script>
        </head>
        <xhtml:body>
          Visible content only
        </xhtml:body>
      </html>
    HTML

    result = Searchable::IndexHelpers.html_to_searchable_string(html)

    assert_not_includes result, "INDEXED_WITH_NAMESPACED_BODY"
    assert_includes result, "Visible content only"
  end

  test "drops very large script payload when body is missing" do
    html = "<html><script>#{large_script_payload}</script><div>visible text</div></html>"

    result = Searchable::IndexHelpers.html_to_searchable_string(html)
    legacy_result = ActionView::Base.full_sanitizer.sanitize(html).gsub(/\s+/, ' ').strip

    assert_operator legacy_result.bytesize, :>, 1_000_000
    assert_equal "visible text", result
  end

  test "drops very large head script payload when body is present" do
    html = "<html><head><script>#{large_script_payload}</script></head><body>visible text</body></html>"

    result = Searchable::IndexHelpers.html_to_searchable_string(html)

    assert_equal "visible text", result
  end

  private

  def large_script_payload
    (1..130_000).map { |i| "tok#{i}" }.join(" ")
  end
end
