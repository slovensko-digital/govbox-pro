class Upvs::XmlDataContainerBuilder

  # TODO make for any form, not only general agenda
  def self.build_xml(message)
    <<~XML
      <xdc:XMLDataContainer xmlns:xdc="http://data.gov.sk/def/container/xmldatacontainer+xml/1.1">
        <xdc:XMLData ContentType="application/xml; charset=UTF-8" Identifier="http://data.gov.sk/doc/eform/App.GeneralAgenda/1.9" Version="#{message.metadata["posp_version"]}">
          #{message.form.content}
        </xdc:XMLData>
        <xdc:UsedSchemasReferenced>
          <xdc:UsedXSDReference DigestMethod="urn:oid:2.16.840.1.101.3.4.2.1" DigestValue="Ctn0B9D7HKn6URFR8iPUKfyGe4mBYpK+25dc1iYWuE=" TransformAlgorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315">http://schemas.gov.sk/form/App.GeneralAgenda/1.9/form.xsd</xdc:UsedXSDReference>
          <xdc:UsedPresentationSchemaReference ContentType="application/xslt+xml" DigestMethod="urn:oid:2.16.840.1.101.3.4.2.1" DigestValue="Qo1jYX1JWydvM/OL/rnirphk1rM1z41fPRXBEgp/qbg=" Language="sk" MediaDestinationTypeDescription="TXT" TransformAlgorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315">http://schemas.gov.sk/form/App.GeneralAgenda/1.9/form.xslt</xdc:UsedPresentationSchemaReference>
        </xdc:UsedSchemasReferenced>
      </xdc:XMLDataContainer>
    XML
  end
end