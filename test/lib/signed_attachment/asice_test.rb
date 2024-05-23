require "test_helper"

class SignedAttachment::AsiceTest < ActiveSupport::TestCase
  test "fills payload documents missing mimetype, file extension from manifest" do
    asice_content = file_fixture('contains_files_without_extensions.asice').read

    asice_payload_documents = SignedAttachment::Asice.extract_documents_from_content(asice_content)

    assert_equal 'application/pdf', asice_payload_documents.first.mimetype
    assert_equal 'COO.2253.102.3.6897861.pdf', asice_payload_documents.first.name

    assert_equal 'application/vnd.gov.sk.xmldatacontainer+xml; charset=UTF-8', asice_payload_documents.second.mimetype
    assert_equal 'COO.2253.102.2.6897875.xml', asice_payload_documents.second.name
  end
end
