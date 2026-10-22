# frozen_string_literal: true

require "test_helper"

class FopTest < ActiveSupport::TestCase
  # Some slovensko.sk form templates have an XPath with 11 groups, which the JDK's XSLT
  # compiler rejects (jdk.xml.xpathExprGrpLimit is 10). The check fails unless FOP runs on
  # Saxon, and the image build runs it too. It skips where fop is not installed.
  test "fop uses Saxon as the XSLT engine" do
    skip "fop is not installed" unless system("command -v fop > /dev/null 2>&1")

    assert system(Rails.root.join("bin/check-fop-saxon").to_s),
           "fop does not use Saxon; form templates with an 11-group XPath fail with JAXP0801001"
  end
end
