# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FopTest < ActiveSupport::TestCase
  # Some slovensko.sk form templates have an XPath with 11 groups, which the JDK's built-in
  # XSLT compiler rejects (jdk.xml.xpathExprGrpLimit is 10). FOP has to run on Saxon: with the
  # JDK compiler it exits with JAXP0801001 and the app gets no PDF at all.
  TEMPLATE = <<~XSL
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
      <xsl:template match="/">
        <fo:root>
          <fo:layout-master-set>
            <fo:simple-page-master master-name="A4"><fo:region-body/></fo:simple-page-master>
          </fo:layout-master-set>
          <fo:page-sequence master-reference="A4">
            <fo:flow flow-name="xsl-region-body">
              <fo:block><xsl:value-of select="(((((((((((/doc/a)))))))))))"/></fo:block>
            </fo:flow>
          </fo:page-sequence>
        </fo:root>
      </xsl:template>
    </xsl:stylesheet>
  XSL

  test "renders a template the JDK XSLT compiler rejects" do
    skip "fop is not installed" unless system("command -v fop > /dev/null 2>&1")

    Dir.mktmpdir do |dir|
      xml = Pathname(dir).join("message.xml")
      xsl = Pathname(dir).join("template.xsl")
      pdf = Pathname(dir).join("out.pdf")
      xml.write("<doc><a>x</a></doc>")
      xsl.write(TEMPLATE)

      assert system("fop", "-xml", xml.to_s, "-xsl", xsl.to_s, "-pdf", pdf.to_s),
             "fop did not render the template; is Saxon the XSLT engine? (JAXP0801001)"

      assert_equal "%PDF-", pdf.binread(5)
    end
  end
end
